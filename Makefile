.SILENT: clean env test qa run debian rm lua luajit luarocks nginx
.PHONY: clean env test qa run debian rm lua luajit luarocks nginx

ENV=$(shell pwd)/env
LUA_VERSION=2.1.0-beta3
LUAROCKS_VERSION=2.4.4
NGINX_VERSION=1.13.10
NGINX_LUA_MODULE_VERSION=v0.10.11

ifeq (Darwin,$(shell uname -s))
  PLATFORM?=macosx
else
  PLATFORM?=linux
endif

clean:
	find src/ -name '*.o' -delete && \
	rm -rf luacov.* luac.out .luacheckcache *.so

env: luarocks
	for rock in lbase64 luaossl luasocket struct utf8 \
			lua-messagepack busted luacov luacheck ; do \
		$(ENV)/bin/luarocks --deps-mode=one install $$rock ; \
	done ; \
	$(ENV)/bin/luarocks install --server=http://luarocks.org/dev lucid

test:
	$(ENV)/bin/busted

qa:
	$(ENV)/bin/luacheck -q src/ spec/

run:
	$(ENV)/bin/nginx -c conf/lucid.conf

debian:
	apt-get install build-essential unzip libncurses5-dev libreadline6-dev \
		libssl-dev

rm: clean
	rm -rf $(ENV)

luajit: rm
	mkdir luajit && \
	wget -c https://github.com/LuaJIT/LuaJIT/archive/v$(LUA_VERSION).tar.gz \
		-O - | tar -xzC luajit --strip-components=1 && \
	cd luajit && \
  	sed -i.bak s%/usr/local%$(ENV)%g src/luaconf.h && \
	sed -i.bak s%./?.lua\"%./?.lua\;./src/?.lua\"%g src/luaconf.h && \
	export MACOSX_DEPLOYMENT_TARGET=10.10 && \
	unset LUA_PATH && unset LUA_CPATH && \
    make -s install PREFIX=$(ENV) INSTALL_INC=$(ENV)/include && \
	ln -sf luajit-$(LUA_VERSION) $(ENV)/bin/lua && \
	cd .. && rm -rf luajit

luarocks: luajit
	wget -qc https://luarocks.org/releases/luarocks-$(LUAROCKS_VERSION).tar.gz \
		-O - | tar -xzf - && \
	cd luarocks-$(LUAROCKS_VERSION) && \
	./configure --prefix=$(ENV) --with-lua=$(ENV) --force-config && \
	make -s build install && \
	cd .. && rm -rf luarocks-$(LUAROCKS_VERSION)

nginx:
	WDIR=`pwd` && \
	cd $(ENV) && \
	rm -rf nginx && \
	mkdir -p conf logs nginx && \
	wget -c https://nginx.org/download/nginx-$(NGINX_VERSION).tar.gz \
		-O - | tar -xzC nginx --strip-components=1 && \
	\
	cd nginx && \
	mkdir -p lua-nginx-module lua-resty-websocket && \
	wget -c https://github.com/openresty/lua-nginx-module/archive/$(NGINX_LUA_MODULE_VERSION).tar.gz \
		-O - | tar -xzC lua-nginx-module --strip-components=1 && \
	wget -c https://github.com/openresty/lua-resty-websocket/archive/v0.06.tar.gz \
		-O - | tar -xzC lua-resty-websocket --strip-components=1 && \
	\
	for lib in lua-resty-websocket/lib ; do \
		for f in $$(cd $$lib ; find ./ -name '*.lua') ; do \
			f=$$(echo $$f | sed -r 's/.\///') ; \
			if=$$(echo $$f | tr '/' '_') ; \
			cp $$lib/$$f $$if ; \
			of=$$(echo $$if | sed -r 's/.lua/.o/') ; \
			$(ENV)/bin/lua -b $$if $$of ; \
		done \
	done ; \
	ar rcs libextra.a *.o ; \
	\
	export LUAJIT_LIB=$(ENV)/lib && \
	export LUAJIT_INC=$(ENV)/include ; \
	./configure --prefix=$(ENV) --without-http_rewrite_module --without-pcre \
		--with-http_stub_status_module \
		--add-module=./lua-nginx-module \
		--with-ld-opt="-L./ -Wl,--whole-archive -lextra -Wl,--no-whole-archive" ; \
	make -j4 ; \
	cd .. && \
	cp nginx/objs/nginx bin/ && \
	cp nginx/conf/mime.types conf/ && \
	ln -sf $$WDIR/etc/nginx.conf conf/lucid.conf && \
	rm -rf nginx

.SILENT: clean env test qa cov run e2e debian rm luajit luarocks nginx
.PHONY: clean env test qa cov run e2e debian rm luajit luarocks nginx

ENV=$(shell pwd)/env
LUA_VERSION=2.1
LUAROCKS_VERSION=3.4.0
NGINX_VERSION=1.19.5
NGINX_LUA_MODULE_VERSION=v0.10.13

ifeq (Darwin,$(shell uname -s))
  PLATFORM?=macosx
else
  PLATFORM?=linux
endif

clean:
	find src/ -name '*.o' -delete && \
	rm -rf luacov.* luac.out .luacheckcache *.so

env: luarocks
	for rock in luasec lbase64 luaossl luasocket struct utf8 lua-cmsgpack \
			busted cluacov luacheck redis-lua lua-ev lua-websockets ; do \
		$(ENV)/bin/luarocks install --deps-mode=one $$rock ; \
	done ; \
	$(ENV)/bin/luarocks install --server=http://luarocks.org/dev lucid

test:
	$(ENV)/bin/busted -v

qa:
	$(ENV)/bin/luacheck -q src/ spec/ *.lua

cov:
	rm -f luacov.* ; env/bin/busted -c ; \
		env/bin/luacov src/ ; tail -18 luacov.report.out

run:
	$(ENV)/bin/nginx -c conf/nginx.conf

e2e:
	redis-cli -h $${REDIS_HOST:-localhost} flushall ; \
	($(ENV)/bin/nginx -c conf/nginx.conf &) ; \
	($(ENV)/bin/lua src/worker.lua &) ; \
	sleep 0.1 ; \
	$(ENV)/bin/lua e2e.lua 4 20 ; \
	killall nginx ; \
	killall lua

debian:
	apt-get install build-essential unzip libncurses5-dev libreadline6-dev \
		libssl-dev libev-dev

rm: clean
	rm -rf $(ENV) luajit luarocks

luajit: rm
	mkdir luajit && cd luajit && \
	wget -c https://github.com/LuaJIT/LuaJIT/archive/v$(LUA_VERSION).tar.gz \
		-O - | tar -xzC . --strip-components=1 && \
 	sed -i.bak s%/usr/local%$(ENV)%g src/luaconf.h && \
	sed -i.bak s%./?.lua\"%./?.lua\;./src/?.lua\"%g src/luaconf.h && \
	export MACOSX_DEPLOYMENT_TARGET=10.10 && \
	unset LUA_PATH && unset LUA_CPATH && \
	make -s install PREFIX=$(ENV) INSTALL_INC=$(ENV)/include && \
	ln -sf $(ENV)/bin/luajit-* $(ENV)/bin/lua && \
	cd .. && rm -rf luajit

luarocks: luajit
	mkdir luarocks && cd luarocks && \
	wget -qc https://luarocks.org/releases/luarocks-$(LUAROCKS_VERSION).tar.gz \
		-O - | tar -xzC . --strip-components=1 && \
	./configure --prefix=$(ENV) --with-lua=$(ENV) --force-config && \
	make -s build install && \
	cd .. && rm -rf luarocks

nginx:
	WDIR=`pwd` && \
	cd $(ENV) && \
	rm -rf nginx && \
	mkdir -p conf logs nginx && \
	wget -c https://nginx.org/download/nginx-$(NGINX_VERSION).tar.gz \
		-O - | tar -xzC nginx --strip-components=1 && \
	\
	cd nginx && \
	mkdir -p lua-nginx-module lua-resty-websocket lua-resty-redis && \
	wget -c https://github.com/openresty/lua-nginx-module/archive/$(NGINX_LUA_MODULE_VERSION).tar.gz \
		-O - | tar -xzC lua-nginx-module --strip-components=1 && \
	wget -c https://github.com/openresty/lua-resty-websocket/archive/v0.08.tar.gz \
		-O - | tar -xzC lua-resty-websocket --strip-components=1 && \
	wget -c https://github.com/openresty/lua-resty-redis/archive/v0.29.tar.gz \
		-O - | tar -xzC lua-resty-redis --strip-components=1 && \
	\
	for lib in lua-resty-websocket/lib lua-resty-redis/lib ; do \
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
		--with-ld-opt="-L./ -Wl,--whole-archive -lextra -Wl,--no-whole-archive \
			-Wl,-rpath,$$LUAJIT_LIB" ; \
	make -j4 ; \
	cd .. && \
	cp nginx/objs/nginx bin/ && \
	cp nginx/conf/mime.types conf/ && \
	ln -sf $$WDIR/etc/nginx.conf conf/nginx.conf && \
	rm -rf nginx

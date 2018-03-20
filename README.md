# Infinite Tiles API

[![Build Status](https://travis-ci.org/akornatskyy/infinite-tiles-api-lua.svg?branch=master)](https://travis-ci.org/akornatskyy/infinite-tiles-api-lua)

Infinite tiles API written using [lua](http://lua.org/) and
[lucid](https://github.com/akornatskyy/lucid) web API toolkit.

# Setup

Install dependencies into virtual environment:

```sh
make env nginx
eval "$(env/bin/luarocks path --bin)"
make test qa
```

# Run

Serve files with a web server:

```sh
make run
```

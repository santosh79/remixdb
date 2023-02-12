clean:
	rm -rf _build

build: clean
	MIX_ENV=dev mix release

build_prod: clean
	MIX_ENV=prod mix release

run: build
	_build/dev/rel/remixdb/bin/remixdb start

run_prod: build_prod
	_build/prod/rel/remixdb/bin/remixdb start

stop:
	_build/dev/rel/remixdb/bin/remixdb stop

stop_prod:
	_build/prod/rel/remixdb/bin/remixdb stop

test: clean
	mix test

PHONY:
	build build_prod

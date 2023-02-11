clean:
	rm -rf _build

build:
	MIX_ENV=dev mix release

build_prod:
	MIX_ENV=prod mix release

run:
	_build/dev/rel/remixdb/bin/remixdb start

run_prod:
	_build/prod/rel/remixdb/bin/remixdb start

stop:
	_build/dev/rel/remixdb/bin/remixdb stop

stop_prod:
	_build/prod/rel/remixdb/bin/remixdb stop

PHONY:
	build build_prod

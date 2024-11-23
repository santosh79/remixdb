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

concatenate:
	@echo "Concatenating project files..."
	@files=$$(find lib test -name '*.ex' -o -name '*.exs' -o -name 'mix.exs'); \
	files="mix.exs $$files"; \
	echo "" > concatenated_project_files.ex; \
	for file in $$files; do \
		echo "Processing: $$file"; \
		echo "# File: $$file" >> concatenated_project_files.ex; \
		echo "" >> concatenated_project_files.ex; \
		cat $$file >> concatenated_project_files.ex; \
		echo "" >> concatenated_project_files.ex; \
	done
	@echo "Files successfully concatenated into concatenated_project_files.ex"

PHONY:
	build build_prod concatenate


build_dir := "./build"

default:
	@just --list

all:
	just release manpage

build:
	dub build

clean:
	dub clean
	rm -r {{build_dir}}

release:
	dub build --build=release
	strip {{build_dir}}/trash

test:
	dub test

coverage:
	mkdir -p {{build_dir}}/coverage
	dub test --coverage
	mv *.lst {{build_dir}}/coverage

lint:
	dub lint

format:
	dub run dfmt -- -i source/**/*.d

manpage:
	scdoc < MANUAL.scd > {{build_dir}}/trash.1


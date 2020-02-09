all: update build


.PHONY: update

update:
	git pull

build:
	mkdocs build

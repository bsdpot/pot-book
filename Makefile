all: update build


.PHONY: update

update:
	git pull

build:
	mkdocs build

docker:
	docker run --rm -it -p 8000:8000 -v ${PWD}:/docs pizzamig/mkdocs

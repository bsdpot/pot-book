all: update build


.PHONY: update

update:
	git pull

.PHONY: build
build:
	mkdocs build

.PHONY: docker-dev
docker-dev:
	docker run --rm -it -p 8000:8000 -v ${PWD}:/docs pizzamig/mkdocs-material-extended

.PHONY: docker-build
docker-build:
	docker -D --log-level="debug" build -t pizzamig/pot-book .

.PHONY: docker-prod
docker-prod:
	docker run --rm -it -p 8000:80 pizzamig/pot-book

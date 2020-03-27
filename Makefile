.PHONY: clean config \
	website https forestry local build \
	dev preview \
	up full \
	push pull

all: push
	@echo done.

clean:
	rm -rf dist
	rm -rf src/home/data/*

config:
	echo posts echos notes home | tr ' ' "\n"	\
		| xargs -I{} -P5 bash -c 'test -d src/{} || mkdir -p src/{}; cat config/global.yaml config/{}.yaml >src/{}/config.yaml'

website:
	test "$(shell basename `pwd`)" != ".preview" || for d in echos notes posts home; do cp -r ../$$d src; done
	echo notes echos posts | tr ' ' "\n" \
		| xargs -I{} -P4 \
			bash -c 'cd src/{}; hugo --quiet -d ../../dist/{} -b "$(PROTO)://$(HOST)/{}" --minify'
	echo notes echos posts | tr ' ' "\n" \
		| xargs -I{} -P4 \
			bash -c 'cd dist/{}; mkdir -p ../../src/home/data/$(PROTO)/index; mv jsonindex.json ../../src/home/data/$(PROTO)/index/{}.json'
	echo notes echos posts | tr ' ' "\n" \
		| xargs -I{} -P4 \
			bash -c 'cd dist/{}; mkdir -p ../../src/home/data/$(PROTO)/feed; cp jsonfeed.json ../../src/home/data/$(PROTO)/feed/{}.json'
	cd src/home && hugo --quiet -d ../../dist -b "$(PROTO)://$(HOST)" --minify
	cp -r static/* dist/

https:
	env NODE_ENV=production ENABLE_MONETIZE=1 $(MAKE) website PROTO=https HOST=the.kalaclista.com

local:
	env NODE_ENV=development ENABLE_MONETIZE=0 $(MAKE) website PROTO=http HOST=localhost:1313

forestry:
	env NODE_ENV=development ENABLE_MONETIZE=0 $(MAKE) website PROTO=https HOST=8ikfjp2kbmkigq.instant.forestry.io

build: clean config
	$(MAKE)	https

preview:
	yarn run forestry

dev:
	yarn run dev

full: pull build
	firebase deploy 

up: pull build
	firebase deploy --only=hosting $(shell test -z "$(FIREBASE_TOKEN)" || echo "--token=$(FIREBASE_TOKEN)")

pull:
	cd src && git pull origin master && cd ../
	git pull origin master

push: pull build deploy

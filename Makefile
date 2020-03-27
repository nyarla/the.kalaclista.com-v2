.PHONY: clean config \
	website http https preview build \
	live up upload deploy

all: push
	@echo done.

clean:
	rm -rf dist
	rm -rf src/home/data/*

config:
	ls src \
		| xargs -I{} -P5 bash -c 'cat config/global.yaml config/{}.yaml >src/{}/config.yaml'

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

preview: clean config
	env NODE_ENV=development ENABLE_MONETIZE=0 $(MAKE) website PROTO=http HOST=localhost:1313

forestry: config
	env NODE_ENV=development ENABLE_MONETIZE=0 $(MAKE) website PROTO=https HOST=8ikfjp2kbmkigq.instant.forestry.io

test: clean config preview live

build: clean config
	$(MAKE)	https

live:
	firebase serve --port 1313

up:
	echo "." >.edit
	tmux-up

deploy:
	firebase deploy 

pull:
	cd src && git pull origin master && cd ../
	git pull origin master

update: pull build
	firebase deploy --only=hosting


push: pull build deploy

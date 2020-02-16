.PHONY: clean config archives \
	website http https preview build \
	live up upload deploy upload-via-aws-codebuild deploy-via-aws-codebuild

all: push
	@echo done.

clean:
	rm -rf dist
	rm -rf src/home/data/*

config:
	ls src \
		| xargs -I{} -P5 bash -c 'cat config/global.yaml config/{}.yaml >src/{}/config.yaml'

archives:
	echo bookmarks echos posts | tr ' ' "\n" \
		| xargs -I[] find src/[]/content -type d \
		| grep -P '\d+' \
		| xargs -I[] -P8 bash -c "echo -e '---\ntype: archive\n---\n' >[]/_index.md"

exists:
	pt --nocolor --nogroup -e '^link: ' src/bookmarks/content \
		| sed 's!src/bookmarks/content!kalaclista:bookmarks!' \
		| sed "s|:[0-9]\\+:link: |\t|" | sed "s|'||g" >static/assets/bookmarks.txt

website:
	echo notes bookmarks echos posts | tr ' ' "\n" \
		| xargs -I{} -P4 \
			bash -c 'cd src/{}; hugo --quiet -d ../../dist/{} -b "$(PROTO)://$(HOST)/{}" --minify'
	echo notes bookmarks echos posts | tr ' ' "\n" \
		| xargs -I{} -P4 \
			bash -c 'cd dist/{}; mkdir -p ../../src/home/data/$(PROTO)/index; mv jsonindex.json ../../src/home/data/$(PROTO)/index/{}.json'
	echo notes bookmarks echos posts | tr ' ' "\n" \
		| xargs -I{} -P4 \
			bash -c 'cd dist/{}; mkdir -p ../../src/home/data/$(PROTO)/feed; cp jsonfeed.json ../../src/home/data/$(PROTO)/feed/{}.json'
	cd src/home && hugo --quiet -d ../../dist -b "$(PROTO)://$(HOST)" --minify
	cp -r static/* dist/

https:
	env NODE_ENV=production ENABLE_MONETIZE=1 $(MAKE) website PROTO=https HOST=the.kalaclista.com

preview: clean config archives exists
	env NODE_ENV=development ENABLE_MONETIZE=0 $(MAKE) website PROTO=http HOST=localhost:5000

build: clean config archives exists
	$(MAKE)	https

live:
	firebase serve

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

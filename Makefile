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
		| grep -P '\d+' | sed 's!src/\([^/]\+\)/content/!src/home/content/\1/!' \
		| xargs -I[] -P8 bash -c "test -e []/_index.md || (mkdir -p []; echo -e '---\ntype: archive\n---\n' >[]/_index.md)"

exists:
	pt --nocolor --nogroup -e '^link: ' src/bookmarks/content \
		| sed 's!src/bookmarks/content!kalaclista:bookmarks!' \
		| sed "s|:[0-9]\\+:link: |\t|" | sed "s|'||g" >static/assets/bookmarks.txt


website:
	echo notes bookmarks echos posts | tr ' ' "\n" \
		| xargs -I{} -P4 \
			bash -c 'cd src/{}; hugo --quiet -d ../../dist/$(PROTO)/{} -b "$(PROTO)://$(HOST)/{}" --minify'
	echo notes bookmarks echos posts | tr ' ' "\n" \
		| xargs -I{} -P4 \
			bash -c 'cd dist/$(PROTO)/{}; mkdir -p ../../../src/home/data/$(PROTO)/index; mv jsonindex.json ../../../src/home/data/$(PROTO)/index/{}.json'
	echo notes bookmarks echos posts | tr ' ' "\n" \
		| xargs -I{} -P4 \
			bash -c 'cd dist/$(PROTO)/{}; mkdir -p ../../../src/home/data/$(PROTO)/feed; cp jsonfeed.json ../../../src/home/data/$(PROTO)/feed/{}.json'
	cd src/home && hugo --quiet -d ../../dist/$(PROTO) -b "$(PROTO)://$(HOST)" --minify
	cp -r static/* dist/$(PROTO)/

http:
	env NODE_ENV=production ENABLE_AMAZON=0 $(MAKE) website PROTO=http HOST=kalaclista.com

https:
	env NODE_ENV=production ENABLE_AMAZON=1 $(MAKE) website PROTO=https HOST=the.kalaclista.com

preview: clean config archives exists
	env NODE_ENV=development ENABLE_AMAZON=0 $(MAKE) website PROTO=http HOST=localhost:1313

build: clean config archives exists
	echo http https | tr ' ' "\n" | xargs -I[] -P2 $(MAKE) []

live:
	nix-shell --run "python3 -m http.server -d dist/http 1313" -p python3

up:
	echo "." >.edit
	tmux-up

upload:
	rsync -e "ssh -p 57092 -i ~/.ssh/id_$(DOMAIN)" \
		-rtOu --modify-window=1 --delete dist/$(PROTO)/ www-data@web.internal.nyarla.net:/data/dist/$(DOMAIN)/

deploy:
	echo kalaclista.com the.kalaclista.com | tr ' ' "\n" \
		| xargs -I{} -P2 bash -c 'make upload DOMAIN={} PROTO=$$(bash -c "test {} = kalaclista.com && echo http || echo https")'

upload-via-aws-codebuild:
	rsync -e "ssh -p 57092 -i ~/.ssh/id_$(DOMAIN) -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" \
		-rtOu --modify-window=1 --delete dist/http/ www-data@web.internal.nyarla.net:/data/dist/$(DOMAIN)/

deploy-via-aws-codebuild:
	echo kalaclista.com the.kalaclista.com | tr ' ' "\n" \
		| xargs -I{} -P2 $(MAKE) upload-via-aws-codebuild DOMAIN={}

pull:
	cd src && git pull origin master && cd ../
	git pull origin master

push: pull build deploy

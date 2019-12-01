.PHONY: all clean fixup _build_config _build_dist _build_archives

all:
	@echo stub

clean:
	rm -rf dist
	rm -rf src/home/data/*

fixup:
	find src -type f -name '*.md' | grep -v '_index.md' \
		| xargs -I{} perl scripts/fixup-entries.pl {};

_build_config:
	cat config/global.yaml config/$(WEBSITE).yaml >src/$(WEBSITE)/config.yaml

_build_dist:
	cd src/$(WEBSITE) && hugo -d ../../dist/$(PROTO)/$(WEBSITE) -b "$(PROTO)://$(HOST)/$(WEBSITE)" --minify && cd ../../

_build_archives:
	cd src/$(WEBSITE)/content \
		&& find . -type d 			\
		| sed "s!\./\?!!g" 			\
		| grep -vP "^$$" 				\
		| xargs -P8 -I{} sh -c 'test -e "{}/_index.md" || perl -e "print qq{---\ntype: $(WEBSITE)\ndate: @{[ join q{-}, (split qr{/}, q[{}]) ]}\n---\n\n}" >{}/_index.md' 

.PHONY: build-bookmarks-prepare build-bookmarks-http build-bookmarks-https preview-bookmarks check-bookmarks

build-bookmarks-prepare:
	@$(MAKE) WEBSITE=bookmarks _build_config
	@$(MAKE) WEBSITE=bookmarks _build_archives

build-bookmarks-https:
	@env NODE_ENV=production ENABLE_AMAZON=1 $(MAKE) WEBSITE=bookmarks PROTO=https HOST=the.kalaclista.com _build_dist

build-bookmarks-http:
	@env NODE_ENV=production ENABLE_AMAZON=0 $(MAKE) WEBSITE=bookmarks PROTO=http HOST=kalaclista.com _build_dist

build-bookmarks: build-bookmarks-prepare
	@$(MAKE) build-bookmarks-http build-bookmarks-https

preview-bookmarks: build-bookmarks-prepare
	@env NODE_ENV=development ENABLE_AMAZON=0 $(MAKE) WEBSITE=bookmarks PROTO=http HOST=localhost:1313 _build_dist

check-bookmarks:
	@pt -N --nogroup '  - ' src/bookmarks/content | cut -d: -f2 \
		| sed 's/  - //' | grep -vP "[^a-zA-Z0-9\-]+" | sort | uniq

.PHONY: build-echos-prepare build-echos-http build-echos-https preview-echos 

build-echos-prepare:
	@$(MAKE) WEBSITE=echos _build_config
	@$(MAKE) WEBSITE=echos _build_archives

build-echos-https:
	@env NODE_ENV=production ENABLE_AMAZON=1 $(MAKE) WEBSITE=echos PROTO=https HOST=the.kalaclista.com _build_dist

build-echos-http:
	@env NODE_ENV=production ENABLE_AMAZON=0 $(MAKE) WEBSITE=echos PROTO=http HOST=kalaclista.com _build_dist

build-echos: build-echos-prepare
	@$(MAKE) build-echos-http build-echos-https

preview-echos: build-echos-prepare
	@env NODE_ENV=development ENABLE_AMAZON=0 $(MAKE) WEBSITE=echos PROTO=http HOST=localhost:1313 _build_dist


.PHONY: build-notes-prepare build-notes-http build-notes-https preview-notes 

build-notes-prepare:
	@$(MAKE) WEBSITE=notes _build_config
	@$(MAKE) WEBSITE=notes _build_archives

build-notes-https:
	@env NODE_ENV=production ENABLE_AMAZON=1 $(MAKE) WEBSITE=notes PROTO=https HOST=the.kalaclista.com _build_dist

build-notes-http:
	@env NODE_ENV=production ENABLE_AMAZON=0 $(MAKE) WEBSITE=notes PROTO=http HOST=kalaclista.com _build_dist

build-notes: build-notes-prepare
	@$(MAKE) build-notes-http build-notes-https

preview-notes: build-notes-prepare
	@env NODE_ENV=development ENABLE_AMAZON=0 $(MAKE) WEBSITE=notes PROTO=http HOST=localhost:1313 _build_dist

.PHONY: build-posts-prepare build-posts-http build-posts-https preview-posts check-posts 

build-posts-prepare:
	@$(MAKE) WEBSITE=posts _build_config
	@$(MAKE) WEBSITE=posts _build_archives

build-posts-https:
	@env NODE_ENV=production ENABLE_AMAZON=1 $(MAKE) WEBSITE=posts PROTO=https HOST=the.kalaclista.com _build_dist

build-posts-http:
	@env NODE_ENV=production ENABLE_AMAZON=0 $(MAKE) WEBSITE=posts PROTO=http HOST=kalaclista.com _build_dist

build-posts: build-posts-prepare
	@$(MAKE) build-posts-http build-posts-https

preview-posts: build-posts-prepare
	@env NODE_ENV=development ENABLE_AMAZON=0 $(MAKE) WEBSITE=posts PROTO=http HOST=localhost:1313 _build_dist

check-posts:
	@pt -N --nogroup '  - ' src/posts/content | cut -d: -f2 \
		| sed 's/  - //' | grep -vP "[^a-zA-Z0-9\-]+" | sort | uniq

.PHONY: build-home-prepare-data build-home-prepare build-home-http build-home-https build-home preview-home

build-home-prepare-data:
	@cp dist/$(PROTO)/$(WEBSITE)/jsonfeed.json src/home/data/feed/$(WEBSITE).json
	@test ! -e dist/$(PROTO)/$(WEBSITE)/jsonindex.json || mv dist/$(PROTO)/$(WEBSITE)/jsonindex.json src/home/data/index/$(WEBSITE).json

build-home-prepare:
	@test -d src/home/data/index || mkdir -p src/home/data/index
	@test -d src/home/data/feed || mkdir -p src/home/data/feed
	@echo "posts echos notes bookmarks" \
			| tr " " "\n" \
			| xargs -P8 -I{} $(MAKE) PROTO=$(PROTO) WEBSITE={} build-home-prepare-data
	@$(MAKE) WEBSITE=home _build_config

build-home-http:
	@$(MAKE) PROTO=http build-home-prepare
	cd src/$(WEBSITE) && env NODE_ENV=production ENABLE_AMAZON=0 hugo -d ../../dist/http -b "http://kalaclista.com" --minify && cd ../../

build-home-https:
	@$(MAKE) PROTO=https build-home-prepare
	cd src/$(WEBSITE) && env NODE_ENV=production ENABLE_AMAZON=1 hugo -d ../../dist/https -b "https://the.kalaclista.com" --minify && cd ../../

build-home:
	@$(MAKE) WEBSITE=home build-home-http
	@$(MAKE) WEBSITE=home build-home-https
	@cp -r static/* dist/http/
	@cp -r static/* dist/https/

preview-home:
	@$(MAKE) PROTO=http build-home-prepare
	cd src/home && env NODE_ENV=development ENABLE_AMAZON=0 hugo -d ../../dist/http -b "http://localhost:1313" --minify && cd ../../
	@cp -r static/* dist/http/

build: clean
	@$(MAKE) -j8 build-bookmarks build-echos build-notes build-posts
	@$(MAKE) build-home

build-via-aws-codebuild: clean
	@$(MAKE) -j2 build-bookmarks build-echos build-notes build-posts
	@$(MAKE) build-home

preview: clean	
	@$(MAKE) -j8 preview-bookmarks preview-echos preview-notes preview-posts
	@$(MAKE) preview-home

live:
	nix-shell --run "python3 -m http.server -d dist/http 1313" -p python3

up:
	echo "." >.edit
	tmux-up

deploy:
	rsync -e "ssh -p 57092 -i ~/.ssh/id_kalaclista.com" -rtOuv --modify-window=1 --delete dist/http/ www-data@web.internal.nyarla.net:/data/dist/kalaclista.com/
	rsync -e "ssh -p 57092 -i ~/.ssh/id_the.kalaclista.com" -rtOuv --modify-window=1 --delete dist/https/ www-data@web.internal.nyarla.net:/data/dist/the.kalaclista.com/

deploy-via-aws-codebuild:
	rsync -avz -e "ssh -p 57092 -o 'StrictHostKeyChecking no'" --delete dist/http/  www-data@web.internal.nyarla.net:/data/dist/kalaclista.com
	rsync -avz -e "ssh -p 57092 -o 'StrictHostKeyChecking no'" --delete dist/https/ www-data@web.internal.nyarla.net:/data/dist/the.kalaclista.com

push: build deploy

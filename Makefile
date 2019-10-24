.PHONY: _build clean all up

all:
	@echo stub

clean:
	rm -rf dist

fixup:
	find src -type f -name '*.md' | grep -v '_index.md' \
		| xargs -I{} perl scripts/fixup-entries.pl {};

_build:
	cat config/global.yaml config/$(TARGET).yaml >src/$(TARGET)/config.yaml
	@$(MAKE) prebuild-$(TARGET)
	@$(MAKE) TARGET=$(TARGET) HOST=$(HOST) _build_http _build_https
	@$(MAKE) postbuild-$(TARGET)

_build_http:
	cd src/$(TARGET) && env AMAZON=0 hugo -d ../../dist/http/$(TARGET) -b "http://$(HOST)/$(TARGET)" --minify && cd ../../

_build_https:
	cd src/$(TARGET) && hugo -d ../../dist/https/$(TARGET) -b "https://the.$(HOST)/$(TARGET)" --minify && cd ../../

_prebuild:
	cd src/$(TARGET)/content && find . -type d \
		| grep -P '\d+' \
		| sed 's!^\./!!g' \
		| xargs -P8 -I{} sh -c 'test -e "{}/_index.md" || perl -e "print qq{---\ntype: $(TARGET)\ndate: @{[ join q[-], (split qr[/], q[{}]) ]}\n---\n\n}" >{}/_index.md'



prebuild-bookmarks:
	@$(MAKE) TARGET=bookmarks _prebuild

build-bookmarks:
	@env NODE_ENV=production $(MAKE) AMAZON=1 TARGET=bookmarks HOST=kalaclista.com _build

preview-bookmarks:
	@env NODE_ENV=development $(MAKE) AMAZON=0 TARGET=bookmarks HOST=localhost:1313 _build

postbuild-bookmarks:
	@true



prebuild-echos:
	@$(MAKE) TARGET=echos _prebuild

build-echos:
	@env NODE_ENV=production $(MAKE) AMAZON=1 TARGET=echos HOST=kalaclista.com _build

preview-echos:
	@env NODE_ENV=development	$(MAKE) AMAZON=0 TARGET=echos HOST=localhost:1313 _build

postbuild-echos:
	@true



prebuild-posts:
	@$(MAKE) TARGET=posts _prebuild

build-posts:
	@env NODE_ENV=production $(MAKE) AMAZON=1 TARGET=posts HOST=kalaclista.com _build

preview-posts:
	@env NODE_ENV=development	$(MAKE) AMAZON=0 TARGET=posts HOST=localhost:1313 _build

postbuild-posts:
	@true



prebuild-notes:
	@true

build-notes:
	@env NODE_ENV=production $(MAKE) AMAZON=1 TARGET=notes HOST=kalaclista.com _build

preview-notes:
	@env NODE_ENV=development	$(MAKE) AMAZON=0 TARGET=notes HOST=localhost:1313 _build

postbuild-notes:
	@true


_prebuild-data:
	@test -d src/home/data/index || mkdir -p src/home/data/index
	@cp dist/$(PROTO)/$(TARGET)/jsonfeed.json src/home/data/$(TARGET).json
	@test ! -e dist/$(PROTO)/$(TARGET)/jsonindex.json || mv dist/$(PROTO)/$(TARGET)/jsonindex.json src/home/data/index/$(TARGET).json

prebuild-home:
	@$(MAKE) PROTO=$(PROTO) TARGET=bookmarks _prebuild-data
	@$(MAKE) PROTO=$(PROTO) TARGET=echos _prebuild-data
	@$(MAKE) PROTO=$(PROTO) TARGET=notes _prebuild-data
	@$(MAKE) PROTO=$(PROTO) TARGET=posts _prebuild-data

build-home:
	cat config/global.yaml config/home.yaml >src/home/config.yaml
	@$(MAKE) PROTO=http prebuild-home
	@cd src/home && env NODE_ENV=production AMAZON=0 hugo -d ../../dist/http -b "http://kalaclista.com" --minify && cd ../../
	@$(MAKE) PROTO=https prebuild-home
	@cd src/home && env NODE_ENV=production AMAZON=1 hugo -d ../../dist/https -b "https://the.kalaclista.com" --minify && cd ../../
	@$(MAKE) postbuild-home

preview-home:
	@cat config/global.yaml config/home.yaml >src/home/config.yaml
	@$(MAKE) PROTO=http prebuild-home
	@cd src/home && env NODE_ENV=development AMAZON=0 hugo -d ../../dist/http -b "http://localhost:1313" --minify && cd ../../
	@$(MAKE) PROTO=https prebuild-home
	@cd src/home && env NODE_ENV=development AMAZON=0 hugo -d ../../dist/https -b "https://the.localhost:1313" --minify && cd ../../
	@$(MAKE) postbuild-home

postbuild-home:
	@cp -r static/* dist/http/
	@cp -r static/* dist/https/



build:
	$(MAKE) clean
	$(MAKE) -j8 build-bookmarks build-echos build-posts build-notes
	$(MAKE) build-home

preview:
	$(MAKE) clean
	$(MAKE) -j8 preview-bookmarks preview-echos preview-posts preview-notes
	$(MAKE) preview-home

live:
	nix-shell --run "python3 -m http.server -d dist/http 1313" -p python3

up:
	echo "." >.edit
	tmux-up

push: build
	rsync -e "ssh -p 57092" -rtOuv --modify-window=1 --delete dist/http/ console@web.internal.nyarla.net:/data/dist/kalaclista.com/
	rsync -e "ssh -p 57092" -rtOuv --modify-window=1 --delete dist/https/ console@web.internal.nyarla.net:/data/dist/the.kalaclista.com/

.PHONY: sync patches build verify package clean

sync:
	./scripts/sync.sh

patches:
	./scripts/patches.sh --apply

build:
	./scripts/build.sh

verify:
	./scripts/verify.sh

package:
	./scripts/package.sh

clean:
	./scripts/clean.sh

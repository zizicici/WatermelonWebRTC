.PHONY: sync build verify package clean

sync:
	./scripts/sync.sh

build:
	./scripts/build.sh

verify:
	./scripts/verify.sh

package:
	./scripts/package.sh

clean:
	./scripts/clean.sh


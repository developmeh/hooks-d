.PHONY: test install-bats clean

install-bats:
	./scripts/install-bats-libs.sh

test:
	.test/bats/bats/bin/bats .test/integration/

clean:
	rm -rf .test/bats

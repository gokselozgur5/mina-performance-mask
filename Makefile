SHELL := /bin/bash

.PHONY: source driving verify test preflight

source:
	@test -n "$(MINA_VIDEO)" || (echo "MINA_VIDEO is required" >&2; exit 2)
	@test -n "$(MINA_SOURCE)" || (echo "MINA_SOURCE is required" >&2; exit 2)
	./scripts/extract-source.sh "$(MINA_VIDEO)" "$(MINA_SOURCE)"

driving:
	@test -n "$(DRIVING_VIDEO)" || (echo "DRIVING_VIDEO is required" >&2; exit 2)
	@test -n "$(NORMALIZED_DRIVING)" || (echo "NORMALIZED_DRIVING is required" >&2; exit 2)
	./scripts/normalize-driving.sh "$(DRIVING_VIDEO)" "$(NORMALIZED_DRIVING)"

verify:
	@test -n "$(MINA_SOURCE)" || (echo "MINA_SOURCE is required" >&2; exit 2)
	@test -n "$(NORMALIZED_DRIVING)" || (echo "NORMALIZED_DRIVING is required" >&2; exit 2)
	./scripts/verify-inputs.sh "$(MINA_SOURCE)" "$(NORMALIZED_DRIVING)"

test:
	./tests/test-media-scripts.sh

preflight:
	./scripts/preflight-thor.sh

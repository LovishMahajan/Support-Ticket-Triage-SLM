.PHONY: help sync lint test check validate generate annotate review audit split freeze \
        baseline frontier train eval failures paper video

PY := uv run python

help:
	@echo "Phase 0: sync lint test check"
	@echo "Later phases (stubs until implemented): validate generate annotate review audit"
	@echo "  split freeze baseline frontier train eval failures paper video"

# --- Phase 0 -----------------------------------------------------------------
sync:
	uv sync

lint:
	uv run ruff check .
	uv run ruff format --check .

test:
	uv run pytest

check: lint test

# --- Later phases: each target is wired up in the phase that creates its script.
# Until then it fails loudly so a gate can never be "passed" by a no-op.
define not_yet
	@echo "make $@: not implemented until $(1) (see docs/build-plan.md §8)"; exit 1
endef

validate: ; $(call not_yet,Phase 2)
generate: ; $(call not_yet,Phase 3)
annotate: ; $(call not_yet,Phase 3)
review:   ; $(call not_yet,Phase 3)
audit:    ; $(call not_yet,Phase 4)
split:    ; $(call not_yet,Phase 4)
freeze:   ; $(call not_yet,Phase 4)
baseline: ; $(call not_yet,Phase 5)
frontier: ; $(call not_yet,Phase 5)
train:    ; $(call not_yet,Phase 6)
eval:     ; $(call not_yet,Phase 7)
failures: ; $(call not_yet,Phase 7)
paper:    ; $(call not_yet,Part A4)
video:    ; $(call not_yet,Part B)

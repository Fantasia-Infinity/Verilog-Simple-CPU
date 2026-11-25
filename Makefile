IVERILOG ?= iverilog
VVP      ?= vvp
BUILD    := build

V16 := $(wildcard CPU-16-Bit-Simplified/*.v)
V8  := $(wildcard CPU-8Bit-Simplified/*.v)

TESTS := tb_cpu16 tb_cpu8 tb_isa tb_mul8 tb_mul16

.PHONY: all test lint clean

all: test

$(BUILD):
	@mkdir -p $(BUILD)

$(BUILD)/tb_cpu16.vvp: sim/tb_cpu16.v $(V16) | $(BUILD)
	$(IVERILOG) -g2012 -o $@ $^

$(BUILD)/tb_isa.vvp: sim/tb_isa.v $(V16) | $(BUILD)
	$(IVERILOG) -g2012 -o $@ $^

$(BUILD)/tb_cpu8.vvp: sim/tb_cpu8.v $(V8) | $(BUILD)
	$(IVERILOG) -g2012 -o $@ $^

$(BUILD)/tb_mul8.vvp: sim/tb_mul.v $(V8) | $(BUILD)
	$(IVERILOG) -g2012 -DBIT8 -o $@ $^

$(BUILD)/tb_mul16.vvp: sim/tb_mul.v $(V16) | $(BUILD)
	$(IVERILOG) -g2012 -DBIT16 -o $@ $^

test: $(addprefix $(BUILD)/,$(addsuffix .vvp,$(TESTS)))
	@set -e; \
	for t in $(TESTS); do \
	  printf '%-10s ' "$$t"; \
	  $(VVP) $(BUILD)/$$t.vvp > $(BUILD)/$$t.log 2>&1 || true; \
	  grep -E '\*\*\* (PASS|FAIL)|FAIL ' $(BUILD)/$$t.log | tail -n 20 || true; \
	  if grep -q '\*\*\* FAIL' $(BUILD)/$$t.log; then echo "  -> FAILED"; exit 1; fi; \
	done; \
	echo; echo "all tests passed"

# Compile-only lint pass: shows port-width and similar warnings.
lint:
	@set -e; for d in CPU-16-Bit-Simplified CPU-8Bit-Simplified; do \
	  echo "== $$d =="; \
	  $(IVERILOG) -g2012 -Wall -o $(BUILD)/lint.vvp $$d/*.v; \
	done

clean:
	rm -rf $(BUILD)

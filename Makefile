ROOT = $(abspath .)
BUILD = $(ROOT)/build
SOURCE = $(ROOT)/llvm-project
PREFIX = $(ROOT)

HOST = $(PREFIX)/host
WASM = $(PREFIX)/wasm

FLANG_BIN = $(BUILD)/bin/flang
LLD_BIN = $(BUILD)/bin/lld
FLANG_INCLUDE = $(BUILD)/include/flang
EMSCRIPTEN_LLVM_ROOT = $(shell em-config LLVM_ROOT)

RUNTIME_BUILD = $(BUILD)/runtimes
RUNTIME_TRIPLE = wasm32-unknown-emscripten

FLANG_WASM_CMAKE_VARS := $(FLANG_WASM_CMAKE_VARS)

.PHONY: all
all: flang wasm-runtime

.PHONY: download
download: $(SOURCE)

.PHONY: wasm-runtime
wasm-runtime: $(FLANG_BIN)
	emcmake cmake -G Ninja -S $(SOURCE)/runtimes -B $(RUNTIME_BUILD) \
	  -DCMAKE_BUILD_TYPE=MinSizeRel \
	  -DLLVM_BINARY_DIR=$(BUILD) \
	  -DLLVM_ENABLE_RUNTIMES=flang-rt \
	  -DLLVM_DEFAULT_TARGET_TRIPLE=$(RUNTIME_TRIPLE) \
	  -DCMAKE_Fortran_COMPILER=$(FLANG_BIN) \
	  -DCMAKE_Fortran_COMPILER_WORKS=yes \
	  -DFLANG_RT_INCLUDE_TESTS=OFF \
	  -DFLANG_RT_FORTRAN_MODULES=ON
	TERM=dumb cmake --build $(RUNTIME_BUILD)

$(SOURCE):
	git clone --single-branch -b wasm --depth=1 https://github.com/r-wasm/llvm-project

.PHONY: flang
flang: $(FLANG_BIN)
$(FLANG_BIN): $(SOURCE)
	@mkdir -p $(BUILD)
	cmake -G Ninja -S $(SOURCE)/llvm -B $(BUILD) \
	  -DCMAKE_INSTALL_PREFIX=$(HOST) \
	  -DCMAKE_BUILD_TYPE=MinSizeRel \
	  -DLLVM_DEFAULT_TARGET_TRIPLE="wasm32-unknown-emscripten" \
	  -DLLVM_TARGETS_TO_BUILD="WebAssembly" \
	  -DLLVM_ENABLE_PROJECTS="clang;flang;mlir;lld" \
	  -DFLANG_INCLUDE_TESTS=OFF \
	  -DFLANG_ENABLE_FLANG_RT=OFF \
	  $(FLANG_WASM_CMAKE_VARS)
	TERM=dumb cmake --build $(BUILD)
	$(MAKE) wasm-runtime

.PHONY: install
install: $(FLANG_BIN) wasm-runtime
	mkdir -p $(HOST)/bin
	mkdir -p $(HOST)/llvm/bin
	mkdir -p $(HOST)/include/flang
	mkdir -p $(WASM)/lib
	install -m 755 $(FLANG_BIN) $(HOST)/bin
	ln -sf $(EMSCRIPTEN_LLVM_ROOT)/* $(HOST)/llvm/bin
	rm -f $(HOST)/llvm/bin/lld $(HOST)/llvm/bin/wasm-ld
	install -m 755 $(LLD_BIN) $(HOST)/llvm/bin
	ln -sf lld $(HOST)/llvm/bin/wasm-ld
	install -m 644 $(RUNTIME_BUILD)/lib/clang/*/lib/$(RUNTIME_TRIPLE)/libflang_rt.runtime.a $(WASM)/lib/libFortranRuntime.a
	install -m 644 $(RUNTIME_BUILD)/lib/clang/*/finclude/flang/$(RUNTIME_TRIPLE)/*.mod $(HOST)/include/flang
	find $(FLANG_INCLUDE) -type f -exec install -m 644 {} $(HOST)/include/flang ';'

.PHONY: check
check:
	cmake --build $(BUILD) --target check-all

.PHONY: clean
clean:
	cmake --build $(BUILD) --target clean

.PHONY: clean-runtime
clean-runtime:
	rm -rf $(RUNTIME_BUILD)

.PHONY: clean-all
clean-all:
	rm -rf $(SOURCE) $(BUILD)

# version 1.1.0
all: run

ifdef OS
  # Windows
  EXECUTABLE_FILE ?= example.exe
else
  # Linux
  EXECUTABLE_FILE ?= example
endif

help:
	@echo "Commands:"
	@echo "* clean"
	@echo "* generate"
	@echo "* build"
	@echo "* run"
	@echo "* run_only"

clean:
	@rm -rf ./build/* ./build/.[!.]* ./build/..?*
	@echo "Cleaning done"

build/CMakeCache.txt: CMakeLists.txt
	@cmake -S . -B build -G "Ninja" -DCMAKE_BUILD_TYPE=Debug

generate: build/CMakeCache.txt
.PHONY: generate

./build/$(EXECUTABLE_FILE): generate
	@cmake --build build

build: ./build/$(EXECUTABLE_FILE)
.PHONY: build

run_only:
	@./build/$(EXECUTABLE_FILE)

run: build run_only


# version 1.0.0
all: run

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

./build/example.exe: generate
	cmake --build build

build: ./build/example.exe
.PHONY: build

run_only:
	@./build/example.exe

run: build run_only


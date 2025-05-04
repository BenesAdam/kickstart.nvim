# version 1.1.0
all: run

ifdef OS
  # Windows
  EXECUTABLE_FILE ?= example.exe
else
  # Linux
  EXECUTABLE_FILE ?= example
endif

HOST_DESTINATION ?= root@192.168.7.2

.PHONY: help clean generate build deploy run run_only ssh

help:
	@echo "Commands:"
	@echo "* clean"
	@echo "* generate"
	@echo "* build"
	@echo "* deploy"
	@echo "* run"
	@echo "* run_only"

clean:
	@rm -rf ./build/* ./build/.[!.]* ./build/..?*
	@echo "Cleaning done"

build/CMakeCache.txt: CMakeLists.txt
	@cmake -S . -B build -G "Ninja" -DCMAKE_BUILD_TYPE=Debug

generate: build/CMakeCache.txt

./build/$(EXECUTABLE_FILE): generate
	@cmake --build build

build: ./build/$(EXECUTABLE_FILE)

deploy: build
ifneq ($(OS),Windows_NT)
	@scp build/$(EXECUTABLE_FILE) $(HOST_DESTINATION):/tmp/$(EXECUTABLE_FILE)
endif

run_only:
ifeq ($(OS),Windows_NT)
	@./build/$(EXECUTABLE_FILE)
else
	@ssh $(HOST_DESTINATION) -t "cd /tmp && ./$(EXECUTABLE_FILE)"
endif

run: build run_only

ssh:
	@ssh $(HOST_DESTINATION)


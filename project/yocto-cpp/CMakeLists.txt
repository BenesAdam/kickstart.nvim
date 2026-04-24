## CMake settings
cmake_minimum_required(VERSION 3.10)
project(example_project)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

## Source files
set(SRC_DIR "${CMAKE_SOURCE_DIR}/source")
file(GLOB_RECURSE SOURCE_FILES_CPP "${SRC_DIR}/*.cpp")
file(GLOB_RECURSE SOURCE_FILES_C   "${SRC_DIR}/*.c")
set(ALL_SOURCES ${SOURCE_FILES_CPP} ${SOURCE_FILES_C})

foreach(file_path IN LISTS ALL_SOURCES)
    get_filename_component(abs_path "${file_path}" ABSOLUTE)
    list(APPEND ABSOLUTE_SOURCE_LIST "${abs_path}")
endforeach()

## Header files
set(INCLUDE_DIR "${CMAKE_SOURCE_DIR}/source")
file(GLOB_RECURSE HEADER_FILES_H   "${INCLUDE_DIR}/*.h")
file(GLOB_RECURSE HEADER_FILES_HPP "${INCLUDE_DIR}/*.hpp")
set(ALL_HEADERS ${HEADER_FILES_H} ${HEADER_FILES_HPP})
set(ABSOLUTE_HEADER_DIR_LIST "")

foreach(header IN LISTS ALL_HEADERS)
    get_filename_component(dir "${header}" DIRECTORY)
    get_filename_component(abs_dir "${dir}" ABSOLUTE)
    list(APPEND ABSOLUTE_HEADER_DIR_LIST "${abs_dir}")
endforeach()

list(REMOVE_DUPLICATES ABSOLUTE_HEADER_DIR_LIST)

## Executable
add_executable(example ${ABSOLUTE_SOURCE_LIST})
target_include_directories(example PUBLIC ${ABSOLUTE_HEADER_DIR_LIST})

## Flags
target_compile_options(example PUBLIC
    -std=c++17
    -g
    -Wall
    -Wfloat-conversion
    $<$<CONFIG:Debug>:-O0>
)

## Definitions
target_compile_options(example PUBLIC
    $<$<CONFIG:Debug>:-U_FORTIFY_SOURCE>
    $<$<CONFIG:Debug>:-D_FORTIFY_SOURCE=0>
    $<$<CONFIG:Debug>:-DDEBUG=1>
)

target_compile_definitions(example PUBLIC
)

## LIB GPIOD
find_library(GPIOD_LIBRARY gpiod)
if (NOT GPIOD_LIBRARY)
    message(FATAL_ERROR "libgpiod not found")
endif()

find_library(GPIOD_CXX_LIBRARY gpiodcxx)
if (NOT GPIOD_CXX_LIBRARY)
    message(FATAL_ERROR "libgpiodcxx not found")
endif()

target_link_libraries(example ${GPIOD_LIBRARY} ${GPIOD_CXX_LIBRARY})


cmake_minimum_required(VERSION 3.14)
project(csv_accel LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# ─── Find Python & pybind11 ─────────────────────────────────────────────────
find_package(Python3 REQUIRED COMPONENTS Interpreter Development)

# Try system pybind11 first, then pip-installed
find_package(pybind11 QUIET)
if(NOT pybind11_FOUND)
    execute_process(
        COMMAND ${Python3_EXECUTABLE} -m pybind11 --cmakedir
        OUTPUT_VARIABLE PYBIND11_CMAKE_DIR
        OUTPUT_STRIP_TRAILING_WHITESPACE
        RESULT_VARIABLE PYBIND11_RESULT
    )
    if(PYBIND11_RESULT EQUAL 0)
        list(APPEND CMAKE_PREFIX_PATH "${PYBIND11_CMAKE_DIR}")
        find_package(pybind11 REQUIRED)
    else()
        message(FATAL_ERROR "pybind11 not found. Install: pip install pybind11")
    endif()
endif()

# ─── Build the extension module ──────────────────────────────────────────────
pybind11_add_module(csv_accel src/csv_accel.cpp)

target_compile_options(csv_accel PRIVATE
    -O2
    -Wall
    -Wextra
)

# ─── Install target (optional) ──────────────────────────────────────────────
install(TARGETS csv_accel LIBRARY DESTINATION .)

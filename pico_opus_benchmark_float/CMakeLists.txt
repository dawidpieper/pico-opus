cmake_minimum_required(VERSION 3.12)

set(PICO_SDK_PATH ${CMAKE_CURRENT_LIST_DIR}/../vendor/pico-sdk)

include(${CMAKE_CURRENT_LIST_DIR}/pico_sdk_import.cmake)

project(piwu_benchmark_float C CXX ASM)
set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)

pico_sdk_init()

add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/../vendor/opus build/opus)

    add_executable(piwu_benchmark_float
            ${CMAKE_CURRENT_LIST_DIR}/piwu_benchmark_float.c
            )

    target_link_libraries(piwu_benchmark_float pico_stdlib)
    target_link_libraries(piwu_benchmark_float opus)

    pico_enable_stdio_usb(piwu_benchmark_float 1)
    pico_enable_stdio_uart(piwu_benchmark_float 0)

    pico_add_extra_outputs(piwu_benchmark_float)
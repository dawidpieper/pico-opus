cmake_minimum_required(VERSION 3.12)

set(PICO_SDK_PATH ${CMAKE_CURRENT_LIST_DIR}/../vendor/pico-sdk)

include(${CMAKE_CURRENT_LIST_DIR}/pico_sdk_import.cmake)

project(piwu_benchmark C CXX ASM)
set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)

pico_sdk_init()

set(OPUS_FIXED_POINT ON CACHE BOOL "OPUS_FIXED_POINT")

add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/../vendor/opus build/opus)

    add_executable(piwu_benchmark
            ${CMAKE_CURRENT_LIST_DIR}/piwu_benchmark.c
            )

    target_link_libraries(piwu_benchmark pico_stdlib)
    target_link_libraries(piwu_benchmark opus)

    pico_enable_stdio_usb(piwu_benchmark 1)
    pico_enable_stdio_uart(piwu_benchmark 0)

    pico_add_extra_outputs(piwu_benchmark)
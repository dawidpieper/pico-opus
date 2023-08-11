cmake_minimum_required(VERSION 3.12)

set(PICO_SDK_PATH ${CMAKE_CURRENT_LIST_DIR}/../vendor/pico-sdk)
set(PICO_EXTRAS_PATH ${CMAKE_CURRENT_LIST_DIR}/../vendor/pico-extras)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/build)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/build)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)


include(${CMAKE_CURRENT_LIST_DIR}/pico_sdk_import.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/pico_extras_import.cmake)

project(piwu C CXX ASM)
set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)

pico_sdk_init()

include(${CMAKE_CURRENT_LIST_DIR}/pico_audio_i2s_cs4344_import.cmake)

set(OPUS_FIXED_POINT ON CACHE BOOL "OPUS_FIXED_POINT")

add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/../vendor/opus build/opus)

    add_executable(piwu
            ${CMAKE_CURRENT_LIST_DIR}/piwu.c
            )

    target_link_libraries(piwu pico_stdlib)
    target_link_libraries(piwu pico_multicore)
    target_link_libraries(piwu hardware_pio)
    target_link_libraries(piwu opus)
    target_link_libraries(piwu pico_audio_i2s_cs4344)

target_compile_definitions(piwu PRIVATE
    USE_AUDIO_I2S=1
)

    pico_enable_stdio_usb(piwu 1)
    pico_enable_stdio_uart(piwu 0)

    pico_add_extra_outputs(piwu)
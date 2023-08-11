if (NOT TARGET pico_audio_i2s_cs4344)
    add_library(pico_audio_i2s_cs4344 INTERFACE)

    pico_generate_pio_header(pico_audio_i2s_cs4344 ${CMAKE_CURRENT_LIST_DIR}/cs4344/audio_i2s.pio)

    target_sources(pico_audio_i2s_cs4344 INTERFACE
            ${CMAKE_CURRENT_LIST_DIR}/../vendor/pico-extras/src/rp2_common/pico_audio_i2s/audio_i2s.c
    )

    target_include_directories(pico_audio_i2s_cs4344 INTERFACE ${CMAKE_CURRENT_LIST_DIR}/../vendor/pico-extras/src/rp2_common/pico_audio_i2s/include)
    target_link_libraries(pico_audio_i2s_cs4344 INTERFACE hardware_dma hardware_pio hardware_irq pico_audio)
endif()
#define PICO_AUDIO_I2S_DATA_PIN 22
#define PICO_AUDIO_I2S_CLOCK_PIN_BASE 26

#define VOLUME_MULTIPLIER 1

#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <math.h>
#include <string.h>
#include "pico/stdlib.h"
#include "pico/multicore.h"
#include "hardware/pll.h"
#include "hardware/clocks.h"
#include "hardware/structs/clocks.h"
#include "hardware/gpio.h"
#include "hardware/sync.h"
#include "hardware/structs/ioqspi.h"
#include "hardware/structs/sio.h"
#include "hardware/pio.h"
#include "hardware/clocks.h"
#include "opus.h"
#include "audiodata.c"
#include "pico/audio_i2s.h"

#define BUFFER_FRAMES 240 / OPUS_FRAMESIZE

audio_buffer_pool_t * ap;
audio_buffer_pool_t * init_audio() {
  static audio_format_t audio_format = {
    .format = AUDIO_BUFFER_FORMAT_PCM_S16,
    .sample_freq = OPUS_SAMPLERATE * 2,
    .channel_count = 2
  };

  static audio_buffer_format_t producer_format = {
    .format = & audio_format,
    .sample_stride = 4
  };

  audio_buffer_pool_t * producer_pool = audio_new_producer_pool( & producer_format, 2,
    OPUS_FRAMESAMPLES);
  const audio_format_t * output_format;
  audio_i2s_config_t config = {
    .data_pin = PICO_AUDIO_I2S_DATA_PIN,
    .clock_pin_base = PICO_AUDIO_I2S_CLOCK_PIN_BASE,
    .dma_channel = 0,
    .pio_sm = 0
  };
  output_format = audio_i2s_setup( & audio_format, & config);
  bool ok = audio_i2s_connect(producer_pool);
  audio_i2s_set_enabled(true);
  return producer_pool;
}

int opusNextFrame = 0;

int __no_inline_not_in_flash_func(opusGetNextFrame)(OpusDecoder * decoder, int16_t * buffer) {
  int frameID = opusNextFrame;
  int index = OPUS_INDEXES[opusNextFrame];
  int next = OPUS_INDEXES[opusNextFrame + 1];
  int size = next - index;
  unsigned char * frame = (char * )(OPUS_STREAM + (index * sizeof(char)));
  int decSize = opus_decode(decoder, frame, size, buffer, OPUS_FRAMESAMPLES, 0);
  ++opusNextFrame;
  if (opusNextFrame >= OPUS_FRAMESCOUNT) {
    opus_decoder_ctl(decoder, OPUS_RESET_STATE);
    opusNextFrame = 0;
  }
  return frameID;
}

OpusDecoder * decoder;
int16_t opusFetchBuffer[OPUS_FRAMESAMPLES * 2 * BUFFER_FRAMES];
uint opusFetchBufferSize = 0;

mutex_t mutex;

void core1_entry() {
  int16_t buffer[OPUS_FRAMESAMPLES * 2];
  bool written = true;
  for (;;) {
    if (written) {
      opusGetNextFrame(decoder, buffer);
      written = false;
    } else sleep_ms(OPUS_FRAMESIZE);
    mutex_enter_blocking( & mutex);
    int sizeLeft = BUFFER_FRAMES * OPUS_FRAMESAMPLES * 2 - opusFetchBufferSize;
    if (sizeLeft >= OPUS_FRAMESAMPLES * 2) {
      for (int i = 0; i < OPUS_FRAMESAMPLES * 2; ++i)
        opusFetchBuffer[opusFetchBufferSize + i] = buffer[i];
      opusFetchBufferSize += OPUS_FRAMESAMPLES * 2;
      written = true;
    }
    mutex_exit( & mutex);
  }
}

int opusFillBuffer(audio_buffer_t * buffer) {
  mutex_enter_blocking( & mutex);
  int16_t * samples = (int16_t * ) buffer -> buffer -> bytes;
  int samplesNeeded = buffer -> max_sample_count;
  int i;
  for (i = 0; i < opusFetchBufferSize && i < samplesNeeded; ++i) {
    samples[i] = opusFetchBuffer[i] * VOLUME_MULTIPLIER;
  }
  int size = i;
  for (int i = size; i < opusFetchBufferSize; ++i)
    opusFetchBuffer[i - size] = opusFetchBuffer[i];
  opusFetchBufferSize -= size;
  mutex_exit( & mutex);
  return size / 2;
}

void i2s_callback_func() {
  audio_buffer_t * buffer = take_audio_buffer(ap, true);
  if (buffer == NULL) {
    return;
  }
  int size = opusFillBuffer(buffer);

  buffer -> sample_count = size;
  give_audio_buffer(ap, buffer);
  return;
}

int main() {
  stdio_init_all();
  // Set PLL_USB 96MHz
  pll_init(pll_usb, 1, 1536 * MHZ, 4, 4);
  clock_configure(clk_usb,
    0,
    CLOCKS_CLK_USB_CTRL_AUXSRC_VALUE_CLKSRC_PLL_USB,
    96 * MHZ,
    48 * MHZ);
  // Change clk_sys to be 96MHz.
  clock_configure(clk_sys,
    CLOCKS_CLK_SYS_CTRL_SRC_VALUE_CLKSRC_CLK_SYS_AUX,
    CLOCKS_CLK_SYS_CTRL_AUXSRC_VALUE_CLKSRC_PLL_USB,
    96 * MHZ,
    96 * MHZ);
  // CLK peri is clocked from clk_sys so need to change clk_peri's freq
  clock_configure(clk_peri,
    0,
    CLOCKS_CLK_PERI_CTRL_AUXSRC_VALUE_CLK_SYS,
    96 * MHZ,
    96 * MHZ);
  // Reinit uart now that clk_peri has changed
  stdio_init_all();

  set_sys_clock_khz(270000, true);

  int err;
  decoder = opus_decoder_create(OPUS_SAMPLERATE, 2, & err);

  mutex_init( & mutex);

  multicore_launch_core1(core1_entry);

  sleep_ms(2000);

  ap = init_audio();

  for (;;) {
    i2s_callback_func();
  }
  opus_decoder_destroy(decoder);
  return 0;
}
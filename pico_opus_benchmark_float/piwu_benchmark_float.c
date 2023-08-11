#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <math.h>
#include <string.h>
#include "pico/stdlib.h"
#include "hardware/pll.h"
#include "hardware/clocks.h"
#include "hardware/structs/clocks.h"
#include "hardware/clocks.h"
#include "opus.h"
#include "audiodata.c"

int opusNextFrame[OPUS_STREAMS];

int __no_inline_not_in_flash_func(opusGetNextFrame)(OpusDecoder * decoder, float * buffer, int opusID) {
  int frameID = opusNextFrame[opusID];
  int index = OPUS_INDEXES[OPUS_STARTINDEXES[opusID] + opusNextFrame[opusID]];
  int next = OPUS_INDEXES[OPUS_STARTINDEXES[opusID] + opusNextFrame[opusID] + 1];
  int size = next - index;
  unsigned char * frame = (char * )(OPUS_STREAM + (index * sizeof(char)));
  int decSize = opus_decode_float(decoder, frame, size, buffer, OPUS_FRAMESAMPLES[opusID], 0);
  ++opusNextFrame[opusID];
  if (opusNextFrame[opusID] >= OPUS_FRAMESCOUNT[opusID]) {
    opus_decoder_ctl(decoder, OPUS_RESET_STATE);
    opusNextFrame[opusID] = 0;
  }
  return frameID;
}

OpusDecoder * decoder;
float opusFetchBuffer[OPUS_SAMPLERATE / 1000 * 120 * 2]; // 120 ms is maximum possible framesize

void opusBenchmark(int khz, int frames) {
  set_sys_clock_khz(khz, true);
  printf("CPU khz set to %d.\n", khz);
  for (int i = 0; i < OPUS_STREAMS; ++i) {
    clock_t start = (clock_t) time_us_64() / 1000;
    for (int j = 0; j < frames; ++j)
      opusGetNextFrame(decoder, opusFetchBuffer, i);
    clock_t stop = (clock_t) time_us_64() / 1000;
    printf("Bitrate %d, framesize %d, time %d ms, ratio %f.\n", OPUS_BITRATE[i], OPUS_FRAMESIZE[i], stop - start, ((double)(stop - start)) / (OPUS_FRAMESIZE[i] * frames));
    opus_decoder_ctl(decoder, OPUS_RESET_STATE);
  }
  printf("\n");
}

int main() {
  for (int i = 0; i < OPUS_STREAMS; ++i) opusNextFrame[i] = 0;

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

  int err;
  decoder = opus_decoder_create(OPUS_SAMPLERATE, 2, & err);

  sleep_ms(5000);

  opusBenchmark(48000, 300);
  opusBenchmark(133000, 300);
  opusBenchmark(270000, 300);

  opus_decoder_destroy(decoder);

  set_sys_clock_khz(48000, true);
}
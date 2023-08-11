Modern audio codecs can achieve amazing results. One of the best codecs at very low bitrates is [Opus](https://github.com/xiph/opus).
This demo application shows how Opus encoder can be used to play really long sounds on the Raspberry Pi Pico microcontroller without using any external memory.
For example, you can fit over 7 minutes of audio using 32 kbps compression and still get really acceptable sound quality.

## Testing
I have used [Pico-Audio module from Waveshare](https://www.waveshare.com/pico-audio.htm) for testing and the code is written for CS4344, but can be easily changed to work with any audio output.

## Benchmarks
The tests were performed for 300 frames of a sample audio file.
The ratio here is the time needed to decode the audio versus its duration. This value must be significantly less than one for continuous playback.

| Bitrate (kbps)  / Frame size (ms) | 48 MHz Fixed Point | 48 MHz Float | 133 MHz Fixed Point | 133 MHz Float  | 270 MHz Fixed Point | 270 MHz Float |
| -------- | -------- | -------- | -------- | -------- | -------- | -------- |
|  8 / 10  | 0.458333 | 0.894 | 0.165333 | 0.322667 | 0.081333 | 0.159 |
|  8 / 20  | 0.511333 | 3.069333 | 0.1845 | 1.107667 | 0.090833 | 0.545667 |
|  8 / 40  | 0.287917 | 1.600167 | 0.103917 | 0.577583 | 0.05125 | 0.2845 |
|  8 / 60  | 0.274111 | 1.523278 | 0.098944 | 0.549778 | 0.048722 | 0.270833 |
|  24 / 10 | 0.418333 | 2.012333 | 0.151 | 0.726333 | 0.074333 | 0.358 |
|  24 / 20 | 0.593167 | 3.185833 | 0.214167 | 1.149833 | 0.1055 | 0.566333 |
|  24 / 40 | 0.575083 | 2.944167 | 0.207583 | 1.062583 | 0.10225 | 0.523333 |
|  24 / 60 | 0.341056 | 1.516778 | 0.123056 | 0.547389 | 0.060667 | 0.269611 |
|  48 / 10 | 0.489333 | 1.848 | 0.176667 | 0.667 | 0.087 | 0.328667 |
|  48 / 20 | 0.691167 | 2.911667 | 0.2495 | 1.050667 | 0.123 | 0.5175 |
|  48 / 40 | 0.7195 | 2.978083 | 0.259667 | 1.074833 | 0.127833 | 0.529417 |
|  48 / 60 | 0.387833 | 1.641833 | 0.14 | 0.592556 | 0.068944 | 0.291889 |
|  64 / 10 | 0.552 | 2.461 | 0.199333 | 0.888333 | 0.098333 | 0.437667 |
|  64 / 20 | 0.758167 | 3.497667 | 0.273833 | 1.262333 | 0.134833 | 0.621833 |
|  64 / 40 | 0.719417 | 3.165167 | 0.259667 | 1.142333 | 0.127917 | 0.56275 |
|  64 / 60 | 0.351278 | 1.522333 | 0.126778 | 0.549389 | 0.062444 | 0.270667 |
| 128 / 10 | 0.576667 | 2.233667 | 0.208 | 0.806 | 0.102667 | 0.397 |
| 128 / 20 | 0.8135 | 3.231 | 0.2935 | 1.166167 | 0.1445 | 0.574333 |
| 128 / 40 | 0.692583 | 2.83975 | 0.249833 | 1.024833 | 0.123083 | 0.504833 |
| 128 / 60 | 0.386444 | 1.527889 | 0.139389 | 0.5515 | 0.068722 | 0.271611 |
| -------- | -------- | -------- | -------- | -------- | -------- | -------- |

## What parameters should I use?
It all depends on the application.
Longer frames allow for faster decoding, but require a larger buffer.
At the same time, relatively low or high bitrates are the fastest in decoding. However, it is worth remembering that in most applications, the quality of the audio, for example, sent via I2S or PWM, will mean that choosing higher bitrates will not improve the actual output quality.

## Why audio is not encapsulated?
Normally the opus stream is placed in an ogg container.
In this scenario I gave up on it, because all needed information about frames can be hard coded. Thanks to this, specific audio frames are decoded directly, and thus the program runs faster and uses less memory.
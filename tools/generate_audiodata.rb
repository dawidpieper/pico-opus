# The bitrate of the resulting file, a lower value allows to obtain a smaller data and shorten the decoding time at the expense of quality, in kbps
BITRATE = 56

# The Frame size used for audio encoding, in ms
FRAMESIZE = 20

# List of samplerates supported by Opus Codec
SUPPORTED_SAMPLERATES = [8000, 12000, 16000, 24000, 48000]

require("wavefile")
require("./opus.rb")

if $*.size == 0
  $stderr.puts("Missing argument, run this tool with path to a file which should be converted.")
  exit(1)
end

file = $*[0]

reader = WaveFile::Reader.new(file)
target_format = WaveFile::Format.new(:stereo, :pcm_16, reader.format.sample_rate)
if !SUPPORTED_SAMPLERATES.include?(target_format.sample_rate)
  $stderr.puts("Samplerate is not supported, convert file to one of: #{SUPPORTED_SAMPLERATES.map { |s| s.to_s }.join(", ")}.")
  exit(1)
end
reader.close
reader = WaveFile::Reader.new(file, target_format)
framesamples = target_format.sample_rate / 1000 * FRAMESIZE

encoder = Opus::Encoder.new(target_format.sample_rate, 2)
encoder.bitrate = BITRATE * 1000

frames = []

while reader.current_sample_frame < reader.total_sample_frames
  buffer = reader.read(framesamples)
  samples = buffer.samples
  samples.push([0, 0]) while samples.size < framesamples
  smp = samples.flatten.pack("S*")
  frame = encoder.encode(smp, FRAMESIZE * target_format.sample_rate / 1000)
  frames.push(frame)
end
reader.close
encoder.free

indexes = []
i = 0
for frame in frames
  indexes.push(i)
  i += frame.bytesize
end
indexes.push(i)

text = "const unsigned char OPUS_STREAM[] = {"
for i in 0...frames.size
  frame = frames[i]
  text += frame.unpack("C*").map { |s| s.to_s }.join(", ")
  text += ",\n" if i < frames.size - 1
end
text += "};\n"
text += "const int OPUS_INDEXES[] = {#{indexes.map { |s| s.to_s }.join(", ")}};\n"
text += "#define OPUS_FRAMESCOUNT #{frames.size}\n"
text += "#define OPUS_SAMPLERATE #{target_format.sample_rate}\n"
text += "#define OPUS_FRAMESIZE #{FRAMESIZE}\n"
text += "#define OPUS_FRAMESAMPLES #{FRAMESIZE * target_format.sample_rate / 1000}\n"

IO.binwrite("../pico_opus/audiodata.c", text)

puts("audiodata has been written, total size #{frames.map { |f| f.bytesize }.sum} bytes, total frames #{frames.size}.")

# Frames count to encode
FRAMES_COUNT = 300

# List of samplerates supported by Opus Codec
SUPPORTED_SAMPLERATES = [8000, 12000, 16000, 24000, 48000]

# Bitrates to test
BITRATES = [8, 24, 48, 64, 128]

# Framesizes to test
FRAMESIZES = [10, 20, 40, 60]

require("wavefile")
require("./opus.rb")

if $*.size == 0
  $stderr.puts("Missing argument, run this tool with path to a file which should be converted.")
  exit(1)
end

file = $*[0]

parameters = []
for bitrate in BITRATES
  for framesize in FRAMESIZES
    parameters.push([bitrate, framesize])
  end
end

frames = []
indexes = []
for i in 0...parameters.size
  bitrate, framesize = parameters[i]

  reader = WaveFile::Reader.new(file)
  target_format = WaveFile::Format.new(:stereo, :pcm_16, reader.format.sample_rate)
  if !SUPPORTED_SAMPLERATES.include?(target_format.sample_rate)
    $stderr.puts("Samplerate is not supported, convert file to one of: #{SUPPORTED_SAMPLERATES.map { |s| s.to_s }.join(", ")}.")
    exit(1)
  end
  reader.close
  reader = WaveFile::Reader.new(file, target_format)
  framesamples = target_format.sample_rate / 1000 * framesize

  encoder = Opus::Encoder.new(target_format.sample_rate, 2)
  encoder.bitrate = bitrate * 1000

  frames[i] = []

  while reader.current_sample_frame < reader.total_sample_frames && frames[i].size < FRAMES_COUNT
    buffer = reader.read(framesamples)
    samples = buffer.samples
    samples.push([0, 0]) while samples.size < framesamples
    smp = samples.flatten.pack("S*")
    frame = encoder.encode(smp, framesize * target_format.sample_rate / 1000)
    frames[i].push(frame)
  end
  reader.close
  encoder.free

  indexes[i] = []
  j = 0
  for frame in frames[i]
    indexes[i].push(j)
    j += frame.bytesize
  end
  indexes[i].push(j)
end

text = ""
fframes = frames.flatten.flatten
text = "const unsigned char OPUS_STREAM[] = {"
for i in 0...fframes.size
  frame = fframes[i]
  text += frame.unpack("C*").map { |s| s.to_s }.join(", ")
  text += ",\n" if i < fframes.size - 1
end
text += "};\n"
text += "const int OPUS_INDEXES[] = {"
for i in 0...indexes.size
  text += "#{indexes[i].map { |s| s.to_s }.join(", ")}"
  text += "," if i < indexes.size - 1
  text += "\n"
end
text += "};\n"
text += "const int OPUS_STARTINDEXES[] = {"
prevCount = 0
for i in 0...indexes.size
  text += prevCount.to_s
  text += ", " if i < indexes.size - 1
  prevCount += indexes[i].size
end
text += "};\n"
text += "const int OPUS_FRAMESCOUNT[] = {#{frames.map { |s| s.size.to_s }.join(", ")}};\n"
text += "const int OPUS_FRAMESIZE[] = {#{parameters.map { |ps| ps[1].to_s }.join(", ")}};\n"
text += "const int OPUS_BITRATE[] = {#{parameters.map { |ps| ps[0].to_s }.join(", ")}};\n"
text += "const int OPUS_FRAMESAMPLES[] = {#{parameters.map { |ps| (ps[1] * target_format.sample_rate / 1000).to_s }.join(", ")}};\n"
text += "#define OPUS_SAMPLERATE #{target_format.sample_rate}\n"
text += "#define OPUS_STREAMS #{frames.size}\n"

IO.binwrite("../pico_opus_benchmark/audiodata.c", text)
IO.binwrite("../pico_opus_benchmark_float/audiodata.c", text)

p "#{frames.map { |f| f.map { |s| s.bytesize }.sum }.sum} bytes of audio and #{frames.map { |f| f.size }.sum} frames in total."

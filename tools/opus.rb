# A part of Elten - EltenLink / Elten Network desktop client.
# Copyright (C) 2014-2020 Dawid Pieper
# Elten is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, version 3.
# Elten is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License along with Elten. If not, see <https://www.gnu.org/licenses/>.

require("fiddle")

module Opus
  Opus = Fiddle.dlopen("opus.dll")

  Encoder_create = Fiddle::Function.new(Opus["opus_encoder_create"], [Fiddle::TYPE_INT, Fiddle::TYPE_INT, Fiddle::TYPE_INT, Fiddle::TYPE_VOIDP], Fiddle::TYPE_INT)
  Encoder_destroy = Fiddle::Function.new(Opus["opus_encoder_destroy"], [Fiddle::TYPE_INT], Fiddle::TYPE_INT)
  Encode = Fiddle::Function.new(Opus["opus_encode"], [Fiddle::TYPE_INT, Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT, Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT], Fiddle::TYPE_INT)
  Encoder_ctl = Fiddle::Function.new(Opus["opus_encoder_ctl"], [Fiddle::TYPE_INT, Fiddle::TYPE_INT, Fiddle::TYPE_VOIDP], Fiddle::TYPE_INT)

  Decoder_create = Fiddle::Function.new(Opus["opus_decoder_create"], [Fiddle::TYPE_INT, Fiddle::TYPE_INT, Fiddle::TYPE_VOIDP], Fiddle::TYPE_INT)
  Decoder_destroy = Fiddle::Function.new(Opus["opus_decoder_destroy"], [Fiddle::TYPE_INT], Fiddle::TYPE_INT)
  Decode = Fiddle::Function.new(Opus["opus_decode"], [Fiddle::TYPE_INT, Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT, Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT, Fiddle::TYPE_INT], Fiddle::TYPE_INT)
  Decoder_ctl = Fiddle::Function.new(Opus["opus_decoder_ctl"], [Fiddle::TYPE_INT, Fiddle::TYPE_INT, Fiddle::TYPE_VOIDP], Fiddle::TYPE_INT)

  Get_version_string = Fiddle::Function.new(Opus["opus_get_version_string"], [], Fiddle::TYPE_VOIDP)

  class Encoder
    attr_reader :freq
    attr_reader :ch
    attr_reader :app

    def initialize(freq = 48000, ch = 2, app = :audio)
      @freq, @ch, @app = freq, ch, app
      if app == :voip
        app = 2048
      else
        app = 2049
      end
      err = [0].pack("i")
      @encoder = Encoder_create.call(freq, ch, app, err)
      @mutex = Mutex.new
    end

    def closed?
      @encoder == nil
    end

    def free
      @mutex.synchronize {
        Encoder_destroy.call(@encoder)
        @encoder = nil
      }
    end

    def preskip
      r = [0].pack("i")
      @mutex.synchronize {
        Encoder_ctl.call(@encoder, 4027, r)
      }
      r.unpack("i").first
    end

    def reset
      @mutex.synchronize {
        Encoder_ctl.call(@encoder, 4028, [0].pack("i"))
      }
    end

    def bitrate
      r = [0].pack("i")
      @mutex.synchronize {
        Encoder_ctl.call(@encoder, 4003, r)
      }
      r.unpack("i").first
    end

    def bitrate=(b)
      @mutex.synchronize {
        Encoder_ctl.call(@encoder, 4002, b)
      }
    end

    def vbr
      r = [0].pack("i")
      @mutex.synchronize {
        Encoder_ctl.call(@encoder, 4007, r)
      }
      r.unpack("i").first
    end

    def vbr=(v)
      @mutex.synchronize {
        Encoder_ctl.call(@encoder, 4006, v)
      }
    end

    def cvbr
      r = [0].pack("i")
      @mutex.synchronize {
        Encoder_ctl.call(@encoder, 4021, r)
      }
      r.unpack("i").first
    end

    def cvbr=(v)
      @mutex.synchronize {
        Encoder_ctl.call(@encoder, 4020, v)
      }
    end

    def dtx
      r = [0].pack("i")
      @mutex.synchronize {
        Encoder_ctl.call(@encoder, 4017, r)
      }
      r.unpack("i").first
    end

    def dtx=(d)
      @mutex.synchronize {
        Encoder_ctl.call(@encoder, 4016, d)
      }
    end

    def inband_fec
      r = [0].pack("i")
      @mutex.synchronize {
        Encoder_ctl.call(@encoder, 4013, r)
      }
      r.unpack("i").first == true
    end

    def inband_fec=(f)
      @mutex.synchronize {
        Encoder_ctl.call(@encoder, 4012, (f == true) ? (1) : (0))
      }
    end

    def prediction_disabled
      r = [0].pack("i")
      @mutex.synchronize {
        Encoder_ctl.call(@encoder, 4043, r)
      }
      r.unpack("i").first == 1
    end

    def prediction_disabled=(r)
      @mutex.synchronize {
        Encoder_ctl.call(@encoder, 4042, (r == true) ? (1) : (0))
      }
    end

    def complexity
      r = [0].pack("i")
      @mutex.synchronize {
        Encoder_ctl.call(@encoder, 4011, r)
      }
      r.unpack("i").first
    end

    def complexity=(c)
      @mutex.synchronize {
        Encoder_ctl.call(@encoder, 4010, c)
      }
    end

    def packetloss
      r = [0].pack("i")
      @mutex.synchronize {
        Encoder_ctl.call(@encoder, 4015, r)
      }
      r.unpack("i").first
    end

    def packetloss=(a)
      @mutex.synchronize {
        Encoder_ctl.call(@encoder, 4014, a)
      }
    end

    def signal
      r = [0].pack("i")
      @mutex.synchronize {
        Encoder_ctl.call(@encoder, 4025, r)
      }
      case r.unpack("i").first
      when -1000
        return :auto
      when 3001
        return :voice
      when 3002
        return :music
      end
    end

    def signal=(s)
      g = -1000
      g = 3001 if s == :voice
      g = 3002 if s == :music
      @mutex.synchronize {
        Encoder_ctl.call(@encoder, 4024, g)
      }
    end

    def encode(data, fs)
      out = ("\0" * 1280).b
      sz = 0
      @mutex.synchronize {
        sz = Encode.call(@encoder, data, fs, out, out.bytesize) if @encoder != nil
      }
      return "" if sz <= 0
      return out.byteslice(0...sz).b
    end
  end

  class Decoder
    attr_reader :fs
    attr_reader :ch

    def initialize(freq = 48000, ch = 2)
      @freq, @ch = freq, ch
      err = [0].pack("i")
      @decoder = Decoder_create.call(freq, ch, err)
      @mutex = Mutex.new
    end

    def free
      @mutex.synchronize {
        Decoder_destroy.call(@decoder) if @decoder != nil
        @decoder = nil
      }
    end

    def preskip
      r = [0].pack("i")
      @mutex.synchronize {
        Decoder_ctl.call(@decoder, 4027, r)
      }
      r.unpack("i").first
    end

    def reset
      @mutex.synchronize {
        Decoder_ctl.call(@decoder, 4028, [0].pack("i"))
      }
    end

    def decode(data, fec = false)
      #if fec==true
      #fec=false
      #data=nil
      #end
      @lastsize ||= 0
      sz = 0
      datasize = 0
      if data != nil && data.bytesize > 1
        toc = data.getbyte(0)
        c = toc >> 3
        fs = 2.5 if [16, 20, 24, 28].include?(c)
        fs = 5 if [17, 21, 25, 29].include?(c)
        fs = 10 if [0, 4, 8, 12, 14, 18, 22, 26, 30].include?(c)
        fs = 20 if [1, 5, 9, 13, 15, 19, 23, 27, 31].include?(c)
        fs = 40 if [2, 6, 10].include?(c)
        fs = 60 if [3, 7, 11].include?(c)
        if (toc & 1) == 0 and (toc & 2) == 0
          sz = @freq * @ch * fs / 1000
        elsif ((toc & 1) == 1 and (toc & 2) == 0) or ((toc & 1) == 0 and (toc & 2) == 2)
          sz = @freq * @ch * fs * 2 / 1000
        elsif (toc & 1) == 1 and (toc & 2) == 2
          b = data.getbyte(1)
          n = (b & 1) + (b & 2) + (b & 4) + (b & 8) + (b & 16)
          sz = @freq * @ch * fs * n / 1000
        end
        datasize = data.bytesize
        @lastsize = sz
      else
        sz = @lastsize
      end
      out = ("\0" * sz * 2).b
      s = 0
      @mutex.synchronize {
        s = Decode.call(@decoder, data, datasize, out, sz / @ch, (fec == true) ? (1) : (0)) <= 0 if @decoder != nil && @freq != nil
      }
      return "" if s == 0
      return "" if out.count("\0") == out.bytesize
      return out
    end
  end

  def self.get_version_string
    Get_version_string.call
  end

  def self.get_toc(framesize, channels)
    c = 0
    case framesize
    when 2.5
      c = 16
    when 5
      c = 17
    when 10
      c = 0
    when 20
      c = 1
    when 40
      c = 2
    when 60
      c = 3
    end
    toc = [c << 3].pack("C")
    toc.setbyte(5, 1) if channels == 2
    return toc
  end
end

require 'image'
require 'frame'
require 'dimension'
require 'stringio'
require 'zlib'

# TODO: Rename to WpcEmuDump
class Pin2DmdDump
  attr_reader :frames, :dimensions

  def self.from_file(filename)
    data = File.read(filename, encoding: 'BINARY')

    if data[0..1].bytes == [31, 139] # Magic ID for gzip
      data = Zlib::GzipReader.new(StringIO.new(data), encoding: 'BINARY').read
    end

    # wpc-emu dump format is defined here, and is the source for the following
    # comments (though it probably copied them from vpinmame, our primary goal
    # here is parsing dumps from wpc-emu):
    #
    #   https://github.com/neophob/wpc-emu/blob/a8de4bc8bc92689930a36935cb7fb9326c920327/client/scripts/lib/pin2DmdExport.js
    #
    # const HEADER = [
    #   // RAW as ascii
    #   82, 65, 87,
    #
    #   // VERSION 1
    #   0, 1,
    #
    #   // DMD WIDTH in pixels
    #   128,
    #
    #   // DMD HEIGHT in pixels
    #   32,
    #
    #   // FRAMES PER IMAGE, always 3 for WPC devices
    #   3,
    # ];
    raise "invalid header" unless data[0..2] == "RAW"

    # n = 16-bit big endian
    # C = 8-bit unsigned
    version, width, height, images_per_frame = *data[3..7].unpack("nC3")

    raise "invalid version" unless version == 1
    raise "unexpected height/width: #{width}x#{height}" unless [width, height] == [128, 32]

    dimensions = Dimension.wh(width, height)

    headerLength = 8
    data = data[headerLength..-1]

    frames = []

    frame_bytes = 128*32/8

    bytes_to_read = frame_bytes * images_per_frame + 4
    while data.length >= bytes_to_read
      chunk = data[0..bytes_to_read]
      data = data[bytes_to_read..-1]
      frame = Frame.from_bytes(chunk, dimensions: dimensions, images: images_per_frame)

      frames << frame
    end
    if data.length > 0
      raise "Unexpected trailing bytes: #{data.inspect}"
    end

    new(frames, dimensions: dimensions)
  end

  def initialize(frames, dimensions:)
    @frames = frames
    @dimensions = dimensions
  end
end

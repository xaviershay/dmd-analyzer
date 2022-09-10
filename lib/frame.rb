require 'image'

# I'll probably come to regret this, but here I've said a frame consists
# of multiple images, though in wpc-emu what we're calling an Image here
# is referred to as a frame. (I did this because for our usages that
# naming makes sense and it's particularly confusing for a user with the
# original naming.)
#
# Intensity is typically calculated by counting how many images a pixel
# is on for throughout the frame: 0=off, 1=33%, 2=66%, 3=100%
# We don't care about that here though, and instead generally flatten the
# image to a monochrome variant.
#
# Documentation of frame format is here:
#
#     https://github.com/neophob/wpc-emu/blob/a8de4bc8bc92689930a36935cb7fb9326c920327/lib/boards/elements/output-dmd-display.js#L4
class Frame < Struct.new(:timestamp, :images)
  def monochrome_image
    images.reduce {|x, y| x.add(y) }
  end

  def bytes
    [timestamp].pack("L<") + images.map(&:to_raw).reduce(:+)
  end

  def self.from_bytes(data, dimensions:, images:)
    frame_bytes = (dimensions.w * dimensions.h / 8.0).ceil
    images_per_frame = images

    uptime = data.unpack("L<").first
    data = data[4..-1]
    frame_data = data[0...frame_bytes * images_per_frame]
    data = data[frame_bytes * images_per_frame..-1]

    images = frame_data.chars.each_slice(frame_bytes).map(&:join).map {|x|
      Image.from_raw(x, dimensions: dimensions)
    }

    Frame.new(uptime, images)
  end
end

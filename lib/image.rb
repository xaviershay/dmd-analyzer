require 'bitwise'
require 'base64'
require 'json'

class Image
  def self.from_raw(data, width: 128, height: 32)
    # For some reason each byte is flipped, possible something in bitwise
    # library, or maybe just a quirk of output format.
    new(
      Bitwise.new(data.chars.map {|y|
        y.unpack("B*").map(&:reverse).pack("B*")
      }.join),
      width: width,
      height: height
    )
  end

  def to_raw
    masked_bits.raw.chars.map {|y|
      y.unpack("B*").map(&:reverse).pack("B*")
    }.join
  end

  def to_json(*args)
    attrs = {
      bits: Base64.encode64(@bits.raw),
      width: width,
      height: height
    }

    if @mask.cardinality < width*height
      attrs[:mask] = Base64.encode64(@mask.raw)
    end

    attrs.to_json(*args)
  end

  def self.from_json(json)
    raw = JSON.parse(json)
    bits = Bitwise.new(Base64.decode64(raw.fetch("bits")))

    attrs = {
      width: raw.fetch("width"),
      height: raw.fetch("height")
    }
    if raw["mask"]
      attrs[:mask] = Bitwise.new(Base64.decode64(raw["mask"]))
    end
    new(bits, **attrs)
  end

  def mask_image
    Image.new(mask, width: width, height: height)
  end

  def initialize(bits, width:, height:, mask: nil)
    @bits = bits
    @width = width
    @height = height

    if mask
      @mask = mask
    else
      clear_mask!
    end
  end

  def clear_mask!
    # Need to round up here to there is a trailing byte to handle any trailing
    # bits that aren't byte aligned.
    self.mask = Bitwise.new("\xFF" * (width*height/8.0).ceil)
  end

  def mask!(x, y, w, h)
    self.mask = mask_from_rect(x, y, w, h)
  end

  def fit_to_content
    x_bounds = [width, -1]
    y_bounds = [height, -1]

    ones = masked_bits.indexes

    ones.each do |one_index|
      x = one_index % width
      y = one_index / width

      x_bounds[0] = x if x < x_bounds[0]
      x_bounds[1] = x if x > x_bounds[1]
      y_bounds[0] = y if y < y_bounds[0]
      y_bounds[1] = y if y > y_bounds[1]
    end

    new_width = x_bounds[1] - x_bounds[0] + 1
    new_height = y_bounds[1] - y_bounds[0] + 1

    arr = bits.bits.chars.each_slice(width).to_a
    arr = arr[y_bounds[0]..y_bounds[1]].map do |row|
      row[x_bounds[0]..x_bounds[1]]
    end

    Image.new(
      Bitwise.new([arr.join].pack("B*")),
      width: new_width,
      height: new_height
    )
  end

  def fit_to_masked_content(x, y, w, h)
    x_bounds = [width, -1]
    y_bounds = [height, -1]

    mask = mask_from_rect(x, y, w, h)

    ones = (bits & mask).indexes

    ones.each do |one_index|
      x = one_index % width
      y = one_index / width

      x_bounds[0] = x if x < x_bounds[0]
      x_bounds[1] = x if x > x_bounds[1]
      y_bounds[0] = y if y < y_bounds[0]
      y_bounds[1] = y if y > y_bounds[1]
    end

    new_width = x_bounds[1] - x_bounds[0] + 1
    new_height = y_bounds[1] - y_bounds[0] + 1

    arr = bits.bits.chars.each_slice(width).to_a
    arr = arr[y_bounds[0]..y_bounds[1]].map do |row|
      row[x_bounds[0]..x_bounds[1]]
    end

    Image.new(
      Bitwise.new([arr.join].pack("B*")),
      width: new_width,
      height: new_height
    )
  end

  def ==(other)
    return false unless other

    # TODO: Think through semantics of including mask here or not
    bits.raw == other.bits.raw &&
      width == other.width &&
      height == other.height
  end

  def hash
    [bits.raw, width, height].hash
  end


  def region_empty?(x, y, w, h)
    region_mask = mask_from_rect(x, y, w, h)
    (bits & region_mask).cardinality == 0
  end

  def add(image)
    unless image.width == self.width && image.height == self.height
      raise "dimensions don't match"
    end

    Image.new(self.bits | image.bits, height: height, width: width)
  end

  def formatted(style: :quadrant)
    unpacked = Array.new(width*height)
    (0...width*height).each do |bit_index|
      unpacked[bit_index] =
          masked_bits.set_at?(bit_index) ? 1 : 0
    end

    case style
    when :quadrant
      to_quadrants(unpacked.each_slice(width)).map {|r|
        r.map {|x| quadrant_to_unicode(x) }.join
      }.join("\n")
    when :shaded
      # TODO: This doesn't make sense on Image, should be on Frame
      unpacked.each_slice(128).map do |row|
        row.map {|x| [" ", "░", "▒", "▓"].fetch(x) }.join
      end
    else
      raise "unimplemented style: #{style}"
    end
  end

  def matches_mask?(image)
    (bits & image.mask).raw == image.masked_bits.raw
  end

  attr_reader :width, :height

  protected

  attr_reader :bits, :mask

  def mask=(mask)
    @mask = mask
    @masked_bits = nil
  end

  def masked_bits
    @masked_bits ||= bits & mask
  end

  def mask_from_rect(x, y, w, h)
    y_head = ["0" * width] * y
    y_tail = ["0" * width] * (height - (y + h))
    x_head = "0" * x
    x_tail = "0" * (width - (x + w))

    bs = y_head + [x_head + "1" * w + x_tail] * h + y_tail
    Bitwise.new([bs.join].pack("B*"))
  end

  # This is pretty weird code, see #formatted specs to get an idea of what it's
  # trying to do (group "blocks" of 4 bits into single elements).
  def to_quadrants(input)
    input.each_slice(2).map do |two_rows|
      if two_rows.length == 1
        two_rows << [0] * two_rows[0].length
      end
      a = two_rows.map {|r|
        x = r.each_slice(2).to_a
        if x.last.length == 1
          x.last[1] = 0
        end
        x
      }
      if a.length == 1
        a << [0, 0]
      end
      a[0].zip(a[1]).map(&:flatten)
    end
  end

  def quadrant_to_unicode(quadrant)
    q = quadrant.map {|x| x == 0 ? 0 : 1 }
    {
      [0, 0, 0, 0] => " ",
      [1, 1, 1, 1] => "█",
      [1, 0, 0, 0] => "▘",
      [0, 1, 0, 0] => "▝",
      [0, 0, 1, 0] => "▖",
      [0, 0, 0, 1] => "▗",
      [1, 1, 0, 0] => "▀",
      [0, 0, 1, 1] => "▄",
      [1, 0, 1, 0] => "▌",
      [0, 1, 0, 1] => "▐",
      [1, 0, 0, 1] => "▚",
      [0, 1, 1, 0] => "▞",
      [1, 1, 1, 0] => "▛",
      [1, 1, 0, 1] => "▜",
      [1, 0, 1, 1] => "▙",
      [0, 1, 1, 1] => "▟"
    }.fetch(q)
  end
end

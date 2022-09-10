require 'rspec'
require 'bitwise'
require 'frame'
require 'dimension'
require 'bytes'

describe Frame do
  describe '.from_bytes' do
    it 'works' do
      expected_time = 12345
      frame = Frame.from_bytes([expected_time].pack("L<") + b("\x00\xFF"),
        dimensions: Dimension.wh(2, 2),
        images: 2
      )
      expect(frame.timestamp).to eq(expected_time)
      expect(frame.images[0].formatted).to eq(" ")
      expect(frame.images[1].formatted).to eq("█")
    end
  end
end

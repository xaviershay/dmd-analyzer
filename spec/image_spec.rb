require 'rspec'
require 'bitwise'
require 'image'

describe Image do
  describe 'JSON serialization' do
    it 'generates valid JSON' do
      i = Image.new(Bitwise.new(pack_bits "111101111"), dimensions: [3, 3])

      attrs = JSON.parse(i.to_json)
      expect(attrs.keys.sort).to eq(%w(bits height width))
    end

    it 'goes both ways' do
      i = Image.new(Bitwise.new(pack_bits "111101111"), dimensions: [3, 3])

      expect(Image.from_json(i.to_json)).to eq(i)
    end

    it 'includes mask' do
      i = Image.new(Bitwise.new(pack_bits "111101111"), dimensions: [3, 3])
      i.mask!(0, 0, 1, 1)

      i2 = Image.from_json(i.to_json)

      expect(i.mask_image).to eq(i2.mask_image)
    end
  end

  describe 'equality' do
    it 'is not equal to nil' do
      i = Image.new(Bitwise.new(pack_bits "111101111"), dimensions: [3, 3])
      expect(i  == nil).to eq(false)
    end

    describe '#hash' do
      it 'hashes bits the same' do
        i1 = Image.new(Bitwise.new(pack_bits "111101111"), dimensions: [3, 3])
        i2 = Image.new(Bitwise.new(pack_bits "111101111"), dimensions: [3, 3])
        i3 = Image.new(Bitwise.new(pack_bits "011101111"), dimensions: [3, 3])

        expect(i1.hash).to eq(i2.hash)
        expect(i1.hash).to_not eq(i3.hash)
      end

      it 'includes dimensions in hash' do
        i1 = Image.new(Bitwise.new(pack_bits "111101111"), dimensions: [3, 3])
        i2 = Image.new(Bitwise.new(pack_bits "111101111"), dimensions: [2, 3])
        i3 = Image.new(Bitwise.new(pack_bits "111101111"), dimensions: [3, 2])

        expect(i1.hash).to_not eq(i2.hash)
        expect(i1.hash).to_not eq(i3.hash)
      end
    end
  end

  describe '#add' do
    it 'does an OR combination of two images' do
        i1 = Image.new(Bitwise.new(pack_bits "1000"), dimensions: [2, 2])
        i2 = Image.new(Bitwise.new(pack_bits "0001"), dimensions: [2, 2])
        expected = Image.new(Bitwise.new(pack_bits "1001"), dimensions: [2, 2])

        expect(i1.add(i2)).to eq(expected)
    end
  end

  describe '#region_empty?' do
    it 'only looks at specified region' do
      i = Image.new(Bitwise.new(pack_bits "111101111"), dimensions: [3, 3])

      expect(i.region_empty?(1, 1, 1, 1)).to eq(true)
      expect(i.region_empty?(1, 2, 1, 1)).to eq(false)
      expect(i.region_empty?(2, 1, 1, 1)).to eq(false)
      expect(i.region_empty?(1, 1, 2, 1)).to eq(false)
      expect(i.region_empty?(1, 1, 1, 2)).to eq(false)
      expect(i.region_empty?(0, 1, 2, 1)).to eq(false)
      expect(i.region_empty?(1, 0, 1, 2)).to eq(false)
    end
  end

  describe '#fit_to_masked_content' do
    it 'shrinks along x axis' do
      i = Image.new(Bitwise.new(pack_bits "01010"), dimensions: [5, 1])
      i = i.fit_to_masked_content(0, 0, 5, 1)

      expected = Image.new(Bitwise.new(pack_bits "101"), dimensions: [3, 1])
      expect(i).to eq(expected)
    end

    it 'shrinks along y axis' do
      i = Image.new(Bitwise.new(pack_bits "01010"), dimensions: [1, 5])
      i = i.fit_to_masked_content(0, 0, 1, 5)

      expected = Image.new(Bitwise.new(pack_bits "101"), dimensions: [1, 3])
      expect(i).to eq(expected)
    end

    it 'only considers pixels inside the specfied mask' do
      i = Image.new(Bitwise.new(pack_bits "11011"), dimensions: [5, 1])
      i = i.fit_to_masked_content(1, 0, 3, 1)

      expected = Image.new(Bitwise.new(pack_bits "101"), dimensions: [3, 1])
      expect(i).to eq(expected)
    end
  end

  describe '#to_raw' do
    it 'respects mask' do
      i = Image.new(Bitwise.new("\xFF"), dimensions: [4, 2])

      i.mask!(3, 1, 1, 1)
      expect(i.to_raw).to eq(pack_raw_bits "00000001")

      i.mask!(1, 1, 2, 1)
      expect(i.to_raw).to eq(pack_raw_bits "00000110")

      i.mask!(0, 0, 2, 2)
      expect(i.to_raw).to eq(pack_raw_bits "11001100")

      i.mask!(1, 0, 2, 2)
      expect(i.to_raw).to eq(pack_raw_bits "01100110")
    end
  end

  describe '#formatted' do
    it 'uses unicode block elements' do
      i = Image.new(Bitwise.new(pack_bits "1000"), dimensions: [2, 2])
      expect(i.formatted).to eq("▘")
    end

    it 'handles odd sized images' do
      i = Image.new(Bitwise.new(pack_bits "1"), dimensions: [1, 1])
      expect(i.formatted).to eq("▘")

      i = Image.new(Bitwise.new(pack_bits "101"), dimensions: [3, 1])
      expect(i.formatted).to eq("▘▘")
    end
  end

  def pack_bits(str)
    [str].pack("B*")
  end

  def pack_raw_bits(str)
    # RAW format has bit positions reversed from what you would expect
    [str.reverse].pack("B*")
  end
end

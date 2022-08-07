require 'image'

module DigitMatcher
  class Score1P
    def initialize
      @templates = (0..9).to_a.map do |n|
        [n, (Image.from_json(File.read("masks/dm/digits/large-1p/#{n}.json")) rescue nil)]
      end.select {|_, i| i}
      @separator = Image.from_json(File.read("masks/dm/digits/large-1p/separator.json"))
    end

    def detect(number)
      # TODO: doing a first pass for width might be quicker? Might not be
      # material though.
      return ',' if @separator == number
      t = @templates.detect {|n, template|
        template == number
      }
      t[0] if t
    end
  end

  class Score
    def initialize(label)
      @templates = (0..9).to_a.map do |n|
        [n, (Image.from_json(File.read("masks/dm/digits/#{label}/#{n}.json")) rescue nil)]
      end.select {|_, i| i}
      @separator = Image.from_json(File.read("masks/dm/digits/#{label}/separator.json"))
    end

    def detect(number)
      # TODO: doing a first pass for width might be quicker? Might not be
      # material though.
      return ',' if @separator == number
      t = @templates.detect {|n, template|
        template == number
      }
      t[0] if t
    end
  end
end

module Screen
  class Score
    def initialize(
      mask: "masks/dm/ball.json"
     # digit_matcher: DigitMatcher::Score1P.new)
    )
      @mask = Image.from_json(File.read(mask))
      @matchers_by_height = {
        20 => [DigitMatcher::Score.new("large-1p")],
        16 => [DigitMatcher::Score.new("4p-normal"), DigitMatcher::Score.new("4p-skinny")]
      }

     #  DigitMatcher::Score1P.new
    end

    def add_pixel_to_group(group, pixel)
      group[:max_x] = pixel[0] if pixel[0] > group.fetch(:max_x, -1)
      group[:max_y] = pixel[1] if pixel[1] > group.fetch(:max_y, -1)
      group[:min_x] = pixel[0] if pixel[0] < group.fetch(:min_x, 2 ** 32)
      group[:min_y] = pixel[1] if pixel[1] < group.fetch(:min_y, 2 ** 32)
      group
    end

    def analyze!(image)
      return unless image.matches_mask?(@mask)

      image.mask!(0, 0, 128, 26)

      bits = image.send(:masked_bits).indexes.map {|x| [x % image.width, x / image.width] }

      groups = []

      while true
        current_group = {}
        seed = bits.shift
        break unless seed
        f = lambda do |p|
          current_group = add_pixel_to_group(current_group, p)

          split = bits.partition {|bit|
            bit[0].between?(current_group[:min_x] - 2, current_group[:max_x] + 2) &&
              bit[1].between?(current_group[:min_y] - 2, current_group[:max_y] + 2)
          }

          neighbours = split[0]
          bits = split[1]

          neighbours.each do |n|
            f[n]
          end
        end
        f[seed]
        groups << current_group
      end

      gs = groups.partition do |g|
        g[:max_y] - g[:min_y] > 10
      end

      # if two groups share same height +/- 1 and are less than 3 px away from each other, join them
      # only need to do this if height > threshold
      # join all groups > threshold
      b = gs[0].reduce {|a, b|
        a[:max_x] = [a[:max_x], b[:max_x]].max
        a[:max_y] = [a[:max_y], b[:max_y]].max

        a[:min_x] = [a[:min_x], b[:min_x]].min
        a[:min_y] = [a[:min_y], b[:min_y]].min
        a
      }

      gs[0] = b
      gs = gs.flatten
      gs.each do |g|
        i = image.fit_to_masked_content(g[:min_x], g[:min_y], g[:max_x] - g[:min_x] + 1, g[:max_y] - g[:min_y] + 1)
        # puts i.formatted
      end

      g = gs[0]

      digits_image = image.fit_to_masked_content(g[:min_x], g[:min_y], g[:max_x] - g[:min_x] + 1, g[:max_y] - g[:min_y] + 1)
      region_start = nil
      bounds = []

      # puts digits_image.height
      (0...digits_image.width).each do |x|
        empty = digits_image.region_empty?(x, 0, 1, digits_image.height - 1)
        if !region_start && !empty
          region_start = x
        elsif region_start && empty
          bounds << [region_start, x]
          region_start = nil
        end
      end
      bounds << [region_start, digits_image.width-1]

      ds = [6, ",", 6, 6, 0]
      ds = []
      ds = [1, ",", 2, 5, 0, ",", 0, 0, 0]

      success = true
      digits = []
      matchers = @matchers_by_height.fetch(digits_image.height)
      # puts image.formatted
      bounds.zip(ds).each do |b, d|
        # TODO: 19 is hard coded for 1p big number. It's either 19 or 20
        # depending on if a comma exists.
        i = digits_image.fit_to_masked_content(b[0], 0, b[1] - b[0] + 1, digits_image.height - 1)
       # puts "---"
       # puts i.formatted
       # output_file = "masks/dm/digits/4p-normal/#{d == "," ? "separator" : d}.json"
       # puts output_file
       # puts i.height
       # File.write(output_file, i.to_json)
       # next
        # TODO: Abort after first match
        t = matchers.map {|m| m.detect(i) }.compact.first

        unless t
          success = false
          break
        end

        digits.push t unless t == ','
      end
      if success && !digits.empty?
        total = 0
        digits.reverse.each.with_index.each do |d, i|
          total += d * (10 ** i)
        end

        player = gs
          .sort_by {|g|
            midpoint = [
              (g[:min_x] + (g[:max_x] - g[:min_x]) / 2.0) / (image.width / 2),
              (g[:min_y] + (g[:max_y] - g[:min_y]) / 2.0) / (image.height / 2)
            ]
            midpoint[0] + midpoint[1] * 2
          }
          .map {|g| g[:max_y] - g[:min_y] }
          .each_with_index
          .max_by {|g, i| g }[1] + 1

        {player: player, player_count: gs.size, score: total}
      end
    end
  end
end

# 2p has a gap in middle, a blob bottom right, nothing bottom left
#
# STRAT
#
# Check two empty strip in middle - if both occupied, 1p
# Check swatches to determine if 2p or not
#
#
# ALT STRAT - locate all occupied areas. Biggest one is current.
#   
# Chuck all set pixels in a heap, indexed by x/y
# start with first pixel - add all pixels within 2px of bounds of group
#   if no pixels, start a new group
describe 'extracting scores' do
  def self.fixture(name, score, current, total)
    it "extracts correct data from #{name}" do
      i = Image.from_json(File.read(File.join("spec/fixtures", name + ".json")))

      m = Screen::Score.new
      r = m.analyze!(i)
      expect(r).to eq(
        score: score,
        player: current,
        player_count: total
      )
    end
  end

  fixture "dm/1p-score", 253330, 1, 1
  fixture "dm/2p-1p-score", 6660, 1, 2
  fixture "dm/2p-2p-score", 1000000, 2, 2
  fixture "dm/3p-1p-score", 253330, 1, 3
  fixture "dm/3p-2p-score", 250000, 2, 3
  fixture "dm/3p-3p-score", 250000, 3, 3
  fixture "dm/4p-1p-score", 750000, 1, 4
  fixture "dm/4p-2p-score", 503330, 2, 4
  fixture "dm/4p-3p-score", 1250000, 3, 4
  fixture "dm/4p-4p-score", 10010, 4, 4
  fixture "dm/4p-2p-big-score", 175740040, 2, 4
  fixture "dm/4p-2p-big-score-2", 100000, 2, 4
end

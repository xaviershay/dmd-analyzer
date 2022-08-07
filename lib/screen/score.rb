require 'image'
require 'digit_matcher'
require 'screen/numbers'

module Screen
  # Analyze a standard score screen for an in-progress game. Supports 1-4
  # players.
  class Score
    def initialize(
      mask: "masks/dm/ball.json"
    )
      @mask = Image.from_json(File.read(mask))
      @numbers = Numbers.new
    end

    def analyze!(image, extract_digits: false)
      # Detect a score screen by looking for "BALL" along the bottom
      return unless image.matches_mask?(@mask)

      # Mask out bottom text so only digits remain
      image.mask!(0, 0, 128, 26)

      data = @numbers.analyze!(image, extract_digits: extract_digits)

      if data && data[:most_prominent_number]
        {
          value: data[:most_prominent_number],
          player: data[:most_prominent_index] + 1,
          player_count: data[:count]
        }
      end
    rescue
      image.clear_mask!
      puts image.formatted
      raise
    end

    private

    def add_pixel_to_segment(segment, pixel)
      segment[:max_x] = pixel[0] if pixel[0] > segment.fetch(:max_x, -1)
      segment[:max_y] = pixel[1] if pixel[1] > segment.fetch(:max_y, -1)
      segment[:min_x] = pixel[0] if pixel[0] < segment.fetch(:min_x, 2 ** 32)
      segment[:min_y] = pixel[1] if pixel[1] < segment.fetch(:min_y, 2 ** 32)
      segment
    end
  end
end


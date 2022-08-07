require 'image'
require 'digit_matcher'
require 'screen/numbers'

module Screen
  class Bonus
    def initialize(mask: "masks/dm/total_bonus.json")
      @mask = Image.from_json(File.read(mask))
      @numbers = Numbers.new
    end

    def analyze!(image, extract_digits: false)
      # Detect a bonus screen by detecting "TOTAL BONUS"
      return unless image.matches_mask?(@mask)

      # Mask out bottom text so only digits remain
      image.mask!(0, 12, 128, 20)

      data = @numbers.analyze!(image, extract_digits: extract_digits)

      return unless data

      x = {}
      x.merge!(digit_images: data[:digit_images]) if data[:digit_images]
      if data[:most_prominent_number]
        x.merge!(
          value: data[:most_prominent_number]
        )
      end
      x
    rescue
      puts image.formatted
      raise
    end
  end
end

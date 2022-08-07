require 'digit_matcher'
require 'screen/numbers'

module Screen
  class Combos
    def initialize(mask: "masks/dm/combos.json")
      @mask = Image.from_json(File.read(mask))
      @numbers = Numbers.new
    end

    def analyze!(image, extract_digits: false)
      # Detect a bonus screen by detecting "COMBOS" in top right
      return unless image.matches_mask?(@mask)

      # Mask out COMBOS and bottom text
      image.mask!(0, 0, 34, 16)

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
    end
  end
end

require 'image'
require 'digit_matcher'

module Screen
  # Analyze a standard score screen for an in-progress game. Supports 1-4
  # players.
  class Score
    def initialize(
      mask: "masks/dm/ball.json",
      digits: "masks/dm/digits"
    )
      @mask = Image.from_json(File.read(mask))
      @matchers_by_height = Dir[File.join(digits, "**")].map do |dir|
        DigitMatcher.new(dir)
      end.group_by(&:height).to_h
    end

    def analyze!(image, extract_digits: false)
      # Detect a score screen by looking for "BALL" along the bottom
      return unless image.matches_mask?(@mask)

      # Mask out bottom text so only digits remain
      image.mask!(0, 0, 128, 26)

      # Segment image into pixel groups separated by 2 pixels or more. This is
      # sufficient to separate different player scores, but will also over
      # segment. Never mind, we fix that in the next section.
      #
      # This is a recursive algorithm:
      #   * Take the first pixel
      #   * Identify all "neighbours" (within 2 pixels)
      #   * Repeat for all neighbours
      #   * Once that process terminates, start again with all remaining pixels
      bits = image.coordinates
      segments = []
      while true
        current = {}
        seed = bits.shift
        break unless seed

        f = lambda do |p|
          current = add_pixel_to_segment(current, p)

          neighbours, bits = *bits.partition {|bit|
            bit[0].between?(current[:min_x] - 2, current[:max_x] + 2) &&
            bit[1].between?(current[:min_y] - 2, current[:max_y] + 2)
          }

          neighbours.each do |n|
            f[n]
          end
        end
        f[seed]
        segments << current
      end

      # Now to fix over segmenting. Large digits can be separated by 2 pixels
      # but not by 3. But rather than generically solve that, we make use of
      # the assumption that only one large digit will be on the screen at a
      # single time, so we can stitch together all "large" segments into a
      # single one.
      #
      # Bit of a hack but avoids a lot of complexity.

      # Start by partitioning out all the large segments.
      split = segments.partition do |g|
        g[:max_y] - g[:min_y] > 12
      end

      # Combine all the large segments into a single one by calculating a new
      # bounding box that encompasses all.
      split[0] = split[0].reduce {|a, b|
        a[:max_x] = [a[:max_x], b[:max_x]].max
        a[:max_y] = [a[:max_y], b[:max_y]].max
        a[:min_x] = [a[:min_x], b[:min_x]].min
        a[:min_y] = [a[:min_y], b[:min_y]].min
        a
      }

      # Stich the segments back together again
      segments = split.flatten

      # Because of the algorithm above, we know that the first element is the
      # largest one, and that's what we want to extract the score from.
      largest_segment = segments[0]

      digits_image = image.fit_to_masked_content(
        largest_segment[:min_x],
        largest_segment[:min_y],
        largest_segment[:max_x] - largest_segment[:min_x] + 1,
        largest_segment[:max_y] - largest_segment[:min_y] + 1
      )

      # Split into individual digits by identifying empty vertical lines
      # separating each.
      region_start = nil
      bounds = []

      (0...digits_image.width).each do |x|
        # For this to work for large digits, we need to lop of the bottom pixel
        # to remove the tail from any commas, hence height minus 1.
        empty = digits_image.region_empty?(x, 0, 1, digits_image.height - 1)
        if !region_start && !empty
          region_start = x
        elsif region_start && empty
          bounds << [region_start, x]
          region_start = nil
        end
      end
      bounds << [region_start, digits_image.width-1]

      success = true
      digits = []
      digit_images = []
      matchers = @matchers_by_height.fetch(digits_image.height)
      bounds.each do |b|
        # We also need to lop off the bottom pixel here to avoid any errant
        # comma pixels that might prevent matching.
        i = digits_image.fit_to_masked_content(
          b[0],
          0,
          b[1] - b[0] + 1,
          digits_image.height - 1
        )
        digit_images.push(i)

        # TODO: Abort after first match
        t = matchers.map {|m| m.detect(i) }.compact.first

        unless t
          success = false
          break unless extract_digits
        end

        digits.push t unless t == ','
      end

      data = {}
      if extract_digits
        data[:digit_images] = digit_images
      end
      if success && !digits.empty?
        # Now we have all our digits, calculate the actual score.
        total = digits.reverse.each.with_index.map do |d, i|
          d * (10 ** i)
        end.sum

        # Sort segments by quadrants by taking the midpoint and scaling down to
        # a 2x2 grid, then sorting by index.
        #
        # The current player is the index of the tallest segment.
        player = segments
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

        data.merge!(player: player, player_count: segments.size, score: total)
      end

      data unless data.empty?
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


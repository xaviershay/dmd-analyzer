module Screen
  class Numbers
    def initialize(digits: "masks/dm/digits")
      matchers = Dir[File.join(digits, "**")].map do |dir|
        DigitMatcher.new(dir)
      end
      @matchers_by_height = matchers.group_by {|x| x.height-1}.to_h
    end

    def analyze!(image, extract_digits: false)
      segments = identify_segments(image)
      segments = join_large_segments(segments)


      if segments.length > 4
        return
      end

      # Because of the algorithm above, we know that the first element is the
      # largest one, and that's what we want to extract the score from.
      largest_segment = segments[0]

      return unless largest_segment

      digits_image = image.fit_to_masked_content(
        largest_segment[:min_x],
        largest_segment[:min_y],
        largest_segment[:max_x] - largest_segment[:min_x] + 1,
        largest_segment[:max_y] - largest_segment[:min_y] + 1
      )

      # For this to work for large digits, we need to lop of the bottom pixel
      # to remove the tail from any commas if any, hence height minus 1.
      height = (digits_image.height + 1) / 2 * 2 - 1

      bounds = identify_digits(digits_image, height)


      digits, digit_images = *classify_digits(digits_image, bounds, height)

      data = {}
      if extract_digits
        data[:digit_images] = digit_images
      end
      if digits && !digits.empty?
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
          .max_by {|g, i| g }[1]

        data.merge!(
          most_prominent_index: player,
          most_prominent_number: total,
          count: segments.size
        )
      end

      data unless data.empty?
    end

    private

    # Segment image into rectangular areas separated by 2 pixels or more. This
    # is sufficient to separate different player scores, but will also over
    # segment. Never mind, we fix that in a later step.
    def identify_segments(image)
      # Start by splitting the image into horizontal strips. We know that this
      # will neatly divide all known digit examples into one or two strips.
      bounds = identify_rects(image.transpose)

      # For each horizontal strip, further split it into segments where there
      # is a two-pixel gap.
      #
      # A possible further optimisation is to go straight to digit
      # identification here since we do basically the same algorithm later with
      # a 1px gap to find those.
      segments = bounds.map do |b|
        bheight = b[1] - b[0]
        hbounds = identify_rects(image,
          strip_width: 2,
          y: b[0],
          height: bheight
        )

        [b, hbounds]
      end

      # Flatten all the segments, and while we're at it fit each one to its
      # contents. This is needed in a subsequent step so we can identify the
      # "tallest" segments to stitch together and classify.
      segments.map do |b, hbs|
        hbs.map do |hb|
          min_x = hb[0]
          max_x = hb[1]
          min_y = b[0]
          max_y = b[1]
          i2 = image.fit_to_masked_content(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)
          {
            min_x: min_x,
            max_x: max_x,
            min_y: min_y,
            max_y: min_y + i2.height
          }
        end
      end.flatten
    end

    # Now to fix over segmenting. Large digits can be separated by 2 pixels
    # but not by 3. But rather than generically solve that, we make use of
    # the assumption that only one large digit will be on the screen at a
    # single time, so we can stitch together all "large" segments into a
    # single one.
    #
    # Bit of a hack but avoids a lot of complexity.
    def join_large_segments(segments)
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
      split.flatten
    end

    # Split into individual digits by identifying empty vertical lines
    # separating each.
    def identify_digits(digits_image, height)
      identify_rects(digits_image, strip_width: 1, height: height)
    end

    # Find rectangular areas of pixels separated by straight whitespace. This
    # is weirdly parameterized, but we use very similar variations of it in a
    # few different places and I didn't want to copy it everywhere given how
    # ugly it still is.
    def identify_rects(image, strip_width: 1, y: 0, height: image.height)
      region_start = nil
      bounds = []
      empty = true

      (0...image.width - (strip_width - 1)).each do |x|
        empty = image.region_empty?(x, y, strip_width, height)
        if !region_start && !empty
          region_start = x
        elsif region_start && empty
          bounds << [region_start, x]
          region_start = nil
        end
      end
      bounds << [region_start, image.width-1] if !empty
      bounds
    end

    def classify_digits(digits_image, bounds, height)
      success = true
      digits = []
      digit_images = []

      matchers = @matchers_by_height[height]
      return [nil, []] unless matchers

      bounds.each do |b|
        # We also need to lop off the bottom pixel here to avoid any errant
        # comma pixels that might prevent matching.
        i = digits_image.fit_to_masked_content(
          b[0],
          0,
          b[1] - b[0] + 1,
          height
        )
        digit_images.push(i)

        # Separators are sometimes offset, sometimes not. Very confusing, just
        # always skip them.
        next if i.height <= 3

        # TODO: Abort after first match
        t = matchers.map {|m| m.detect(i) }.compact.first

        unless t
          success = false
          break # TODO: unless extract_digits
        end

        digits.push t unless t == ','
      end

      return [success ? digits : nil, digit_images]
    end
  end
end

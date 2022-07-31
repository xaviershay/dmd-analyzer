require 'benchmark'

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'pin2dmd_dump'

dump = Pin2DmdDump.from_file("data/dm-all-digits.raw")
filename = "masks/dm/ball.raw"
mask = Marshal.load(File.read(filename))

templates = (0..9).to_a.map do |n|
  [n, Marshal.load(File.read("masks/dm/#{n}.raw"))]
end
separator = Marshal.load(File.read("masks/dm/separator.raw"))

n = 5
result = Benchmark.measure do
  n.times do
    dump.frames[0..n].each.with_index do |f, i|
      image = f.monochrome_image
      if image.matches_mask?(mask)
        image.mask!(0, 0, 128, 23) # extract just the numbers

        region_start = nil
        bounds = []

        (0...image.width).each do |x|
          empty = image.region_empty?(x, 0, 1, 23)
          if !region_start && !empty
            region_start = x
          elsif region_start && empty
            bounds << [region_start, x]
            region_start = nil
          end
        end

        digits = []
        success = true
        bounds.each do |bound|
          image.mask!(bound[0], 0, bound[1] - bound[0], 23)
          number = image.fit_to_content
          next if separator == number
          t = templates.detect {|n, template|
            template == number
          }

          unless t
            success = false
            break
          end

          digits.push t[0]
        end

        total = 0
        digits.reverse.each.with_index.each do |d, i|
          total += d * (10 ** i)
        end
      end
    end
  end
end
puts result

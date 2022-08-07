class DigitMatcher
  def initialize(dir)
    @templates = (0..9).to_a.map do |n|
      [n, (Image.from_json(File.read("#{dir}/#{n}.json")) rescue nil)]
    end.select {|_, i| i}
    @separator = Image.from_json(File.read("#{dir}/separator.json"))
  end

  def height
    @templates.first[1].height + 1
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

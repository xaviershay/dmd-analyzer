module Screen
  class Score
    def initialize(
      mask: "masks/dm/ball.json"
     # digit_matcher: DigitMatcher::Score1P.new)
    )
      @mask = Image.from_json(File.read(mask))
    end

    def analyze!(image)
      return unless image.matches_mask?(@mask)
    end
  end
end

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
  fixture "dm/2p-2p-score", 1000000, 1, 2
  fixture "dm/3p-1p-score", 253330, 1, 3
  fixture "dm/3p-2p-score", 250000, 2, 3
  fixture "dm/3p-3p-score", 250000, 3, 3
  fixture "dm/4p-1p-score", 750000, 1, 4
  fixture "dm/4p-2p-score", 100000, 2, 4
  fixture "dm/4p-3p-score", 1250000, 3, 4
  fixture "dm/4p-4p-score", 10010, 4, 4
  fixture "dm/4p-2p-big-score", 175740040, 2, 4
  fixture "dm/4p-2p-big-score-2", 100000, 2, 4
end

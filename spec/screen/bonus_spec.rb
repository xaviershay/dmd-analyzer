require 'image'
require 'screen/bonus'

describe 'extracting bonus' do
  def self.fixture(name, score)
    it "extracts correct data from #{name}" do
      i = Image.from_json(File.read(File.join("spec/fixtures", name + ".json")))

      m = Screen::Bonus.new
      r = m.analyze!(i)
      expect(r).to eq(
        value: score,
      )
    end
  end

  fixture "dm/bonus-1000000", 1_000_000
end

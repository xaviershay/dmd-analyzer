require 'image'
require 'screen/combos'

describe 'extracting combos' do
  def self.fixture(name, count)
    it "extracts correct data from #{name}" do
      i = Image.from_json(File.read(File.join("spec/fixtures", name + ".json")))

      m = Screen::Combos.new
      r = m.analyze!(i)
      expect(r).to eq(
        value: count,
      )
    end
  end

  fixture "dm/combos-2", 2
end

class Dimension < Struct.new(:w, :h)
  def self.wh(w, h)
    new(w, h)
  end
end

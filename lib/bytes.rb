# helper method to translate from default UTF-8 encoding to proper bytes
def b(s)
  s.force_encoding(Encoding::ASCII_8BIT)
end

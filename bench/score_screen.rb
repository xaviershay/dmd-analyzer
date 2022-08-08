require 'benchmark'

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), "..", "lib")
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), "..", "spec")

require 'rspec/core'
require 'screen/score_spec'

class NullFormatter
  RSpec::Core::Formatters.register self

  def initialize(output)
  end
end

require 'ruby-prof'
def maybe_profile(prof)
  RubyProf.start if prof
  yield
  if prof
    result = RubyProf.stop
    printer = RubyProf::GraphHtmlPrinter.new(result)
    File.open("graph.html", "w") {|f| printer.print(f) }

    printer = RubyProf::CallStackPrinter.new(result)
    File.open("calls.html", "w") {|f| printer.print(f) }
  end
end

n = 1
result = nil
maybe_profile(true) do
  result = Benchmark.measure do
    n.times do
      RSpec::Core::Runner.run(%w(-f NullFormatter))
    end
  end
end
puts result

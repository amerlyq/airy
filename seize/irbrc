require 'rubygems'
require 'benchmark'
require 'awesome_print'

def time(&block)
  result = nil
  timing = Benchmark.measure do
    result = block.call
  end
  puts "It took: #{timing}"
  result
end

IRB.conf[:AUTO_INDENT] = true
IRB.conf[:SAVE_HISTORY] = 9000

IRB::Irb.class_eval do
  def output_value
    ap @context.last_value
  end
end

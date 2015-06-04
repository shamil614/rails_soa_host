require 'benchmark'
require 'byebug'
require 'bunny'
require File.expand_path('app/consumers') + '/rpc_consumer'
require File.expand_path('app/consumers') + '/calculator_rpc_consumer'
require 'rake'
require 'rest-client'

namespace :benchmark do
  desc "Compare performance of the Calculator making remote calls via AMQP vs HTTP"
  task :calculator do
    puts "Building Array of values for calculations"
    values = []
    1000.times do
      a = rand(1..100000)
      b = rand(1..100000)
      c = a + b
      values.push [a,b,c]
    end
    bunny = Bunny.new
    bunny.start
    channel = bunny.create_channel

    crc = CalculatorRpcConsumer.new(connection: bunny, channel: channel)
    crc.start

    puts "Running calculations for #{values.count} values"
    puts "You will be alerted if the return value does not meet expectations"
    Benchmark.bm(7) do |bm|
      bm.report('amqp') do
        values.each do |value|
          result =  crc.add([value[0], value[1]])
          puts "AMQP Result #{result} vs expected #{value[2]}" if result != value[2]
        end
      end

      bm.report('http') do
        values.each do |value|
          json = RestClient.post("http://localhost:9292/add", { values: [value[0], value[1]] })
          result = JSON.parse(json)['result']
          puts "HTTP Result #{result} vs expected #{value[2]}" if result != value[2]
        end
      end
    end

  end
end

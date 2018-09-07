require 'yaml'



class LinearCongruential
  attr_reader :seed

  def initialize(seed)
    @seed = @r = seed
  end

  def rand
    @r = (25173 * @r + 13849) % 32768
    @r / 32768.to_f
  end

  def rand_between(range)
    first = range.first
    last = range.last
    (last - first) * rand + first
  end
end



class Queue

  attr_reader :servers, :capacity, :client_count, :input, :output

  def initialize(config)
    @servers = config[:servers]
    @capacity = config[:capacity]
    @input = config[:min_arrival]..config[:max_arrival]
    @output = config[:min_service]..config[:max_service]
    @client_count = 0
  end

  def increment
    @client_count = client_count + 1 if @client_count < @capacity
  end

  def decrement
    @client_count = client_count - 1 if @client_count > 0
  end

  def to_s
    "Queue\n" +
    "server_count: #{@server_count}\n" +
    "capacity: #{@capacity}\n" +
    "client_count: #{@client_count}\n" +
    "Input tax #{@input}\n" +
    "Output tax #{@output}\n"
  end

end



class Simulation

  def initialize(config_file_path)
    @queues = Hash.new
    setup(config_file_path)
  end

  def run
  end

  def to_s
    @queues.each { |q| q.to_s }
  end

  def setup(config_file_path)
    config = YAML.load_file(config_file_path)
    config[:queues].each { |q| @queues[q[:id]] = Queue.new(q) }
  end

  def arrival
  end

  def departure
  end

  private :arrival, :departure, :setup

end



if __FILE__ == $0
  sim = Simulation.new(ARGV[0])
  sim.run
  puts sim.to_s
end


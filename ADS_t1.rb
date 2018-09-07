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

  attr_reader :server_count, :size, :client_count, :input, :output

  def initialize(server_count, size, input, output)
    @server_count = server_count
    @size = size
    @input = input
    @output = output
    @client_count = 0
  end

  def increment
    @client_count = client_count + 1 if @client_count < @size
  end

  def decrement
    @client_count = client_count - 1 if @client_count > 0
  end

  def to_s
    "Queue\n" +
    "server_count: #{@server_count}\n" +
    "size: #{@size}\n" +
    "client_count: #{@client_count}\n" +
    "Input tax #{@input}\n" +
    "Output tax #{@output}\n"
  end

end



class Simulation

  def initialize(config_file_path)
    setup(config_file_path)
  end

  def run
  end

  def to_s
  end

  def setup(config_file_path)
    config = YAML.load_file(config_file_path)
    queues = config[:queues]
    arrivals = config[:arrivals]
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
end


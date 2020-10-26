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

  private :rand

end



class Queue

  attr_reader :id, :servers, :capacity, :client_count, :input, :output, :statistics, :client_lost_count

  def initialize(config)
    @id = config[:id]
    @servers = config[:servers]
    @capacity = config[:capacity]
    @input = config[:min_arrival]..config[:max_arrival]
    @output = config[:min_service]..config[:max_service]
    @client_count = 0
    @client_lost_count = 0
    @statistics = Hash.new
    capacity.times { |i| @statistics[i] = 0 }
    @statistics[capacity] = 0
  end

  def increment
    @client_count = client_count + 1 if @client_count < @capacity
  end

  def decrement
    @client_count = client_count - 1 if @client_count > 0
  end

  def increment_lost_count
    @client_lost_count += 1
  end

  def to_s
    "Queue #{@id}\n" +
    "server_count: #{@server_count}\n" +
    "capacity: #{@capacity}\n" +
    "client_count: #{@client_count}\n" +
    "Input tax #{@input}\n" +
    "Output tax #{@output}\n" +
    "Client Lost #{@client_lost_count}\n" +
    "Statistics #{@statistics.to_s}"
  end

end



class Simulation

  Event = Struct.new(:type, :queue_id, :time)

  def initialize(config_file_path)
    @queues = Hash.new
    @topology = Hash.new
    @events = Array.new
    @statistics = Hash.new
    @event_report = Array.new
    @random = nil
    @duration = 0
    @previous_event_time = 0
    setup(config_file_path)
  end

  def run
    while true
      event = next_event
      break if event.time > @duration
      @event_report << "#{event.queue_id} #{event.type} #{event.time}"
      case event.type
      when :arrival
        arrival(event.queue_id, event.time)
      when :departure
        departure(event.queue_id, event.time)
      when :transfer
        transfer(event.queue_id, event.time)
      end
      @previous_event_time = event.time
    end
  end

  def insert_event(event_type, queue_id, time)
    event = Event.new(event_type, queue_id, time)
    @events << event
  end

  def next_event
    next_event_index = 0
    min_time = Float::MAX
    @events.each_with_index do |event, i|
      if min_time > event.time
        min_time = event.time
        next_event_index = i
      end
    end
    @events.slice!(next_event_index)
  end


  def to_s
    @queues.each { |q| q.to_s }.to_s + "\n" +
    @topology.to_s + "\n" +
    @events.to_s
  end

  def report
    puts "--------------------------------------"
    puts "|         SIMULATION REPORT          |"
    puts "--------------------------------------"
    @event_report.each_with_index do |er, i|
      puts "#{i} - #{er}"
    end
    puts "--------------------------------------"
    puts "Seed: #{@random.seed}"
    @queues.each do |id, queue|
      queue_report = "Queue #{id}:\n"
      queue.statistics.each do |state, time|
        queue_report += "\t#{state} -> #{time}\n\t     #{time * 100 / @previous_event_time}%\n"
      end
      queue_report += "\n\tClients lost: #{queue.client_lost_count}"
      puts queue_report
    end
    puts "--------------------------------------"
  end

  def setup(config_file_path)
    config = YAML.load_file(config_file_path)
    @duration = config[:duration]
    config[:queues].each { |q| @queues[q[:id]] = Queue.new(q) }
    config[:topology].each { |e| @topology[e[:from]] = @queues[e[:to]] } unless config[:topology].nil?
    config[:arrivals].each do |e|
      type = :arrival
      queue_id = e[:queue_id]
      time = e[:time]
      event = Event.new(type, queue_id, time)
      @events << event
    end
    @random = LinearCongruential.new(config[:seed])
  end

  def arrival(queue_id, time)
    record_time(time)
    queue = @queues[queue_id]
    if queue.client_count < queue.capacity
      queue.increment
      if queue.client_count <= queue.servers
        schedule(:departure, queue, time)
      end
    else
      queue.increment_lost_count
    end
    schedule(:arrival, queue, time)
  end

  def transfer(queue_id, time)
    from = @queues[queue_id]
    to = @topology[queue_id]
    record_time(time)
    from.decrement
    schedule(:transfer, from, time) if from.client_count >= from.servers
    if to.client_count < to.capacity
      to.increment
      schedule(:departure, to, time) if to.client_count <= to.servers
    else
      to.increment_lost_count
    end
  end

  def departure(queue_id, time)
    record_time(time)
    queue = @queues[queue_id]
    queue.decrement
    schedule(:departure, queue, time) if queue.client_count >= queue.servers
  end


  def record_time(time)
    @queues.each do |fila_id, queue|
      current_time = queue.statistics[queue.client_count]
      interval = time - @previous_event_time
      new_time = current_time + interval
      queue.statistics[queue.client_count] = new_time
    end
  end

  def schedule(event_type, queue, time)
    if event_type == :departure or event_type == :transfer
      event_type = :transfer unless @topology[queue.id].nil?
      taxa = queue.output
    else
      taxa = queue.input
    end
    time = time + @random.rand_between(taxa)
    insert_event(event_type, queue.id, time)
  end

  private :arrival, :departure, :transfer, :setup, :record_time, :schedule, :insert_event, :next_event

end



if __FILE__ == $0
  sim = Simulation.new(ARGV[0])
  sim.run
  sim.report
end


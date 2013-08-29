SIGNALS_QUEUE = []

[:INT, :TERM, :QUIT].each do |sig|
  Signal.trap(sig) { SIGNALS_QUEUE << sig }
end

loop do
  case SIGNALS_QUEUE.shift
  when :INT
    puts "Sending signal ...."
    sleep 2
    puts "Reaping children"
    exit
  when :TERM
  when :QUIT
  else
    # other housekeeping behaviour for the run loop
    sleep 2
  end
end

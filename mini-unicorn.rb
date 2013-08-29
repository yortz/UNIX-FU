require 'socket'
require 'rack'
require 'rack/builder'
require 'http_tools'

class MiniUnicorn

  NUM_WORKERS = 4
  CHILD_PIDS = []
  SIGNAL_QUEUE = []

  def initialize(port=8080)
    #socket(2)
    @listener = Socket.new(:INET, :STREAM)

    #bind(2)
    @listener.bind(Socket.sockaddr_in(port, '0.0.0.0'))

    #listen(2)
    @listener.listen(512)
  end

  def start
    load_app
    spawn_workers
    trap_signals
    set_title

    loop do
      case SIGNAL_QUEUE.shift
      when :INT, :QUIT, :TERM
        shutdown
    end
  end

  def trap_signals
    [:INT, :QUIT, :TERM].each do |sig|
      Signal.trap(sig) { SIGNAL_QUEUE << sig }
    end
  end

  def shutdown
    at_exit {
      CHILD_PIDS.each do |cpid|
        Process.waitpid(cpid, :WNOHANG)
        Proces.kill[:INT, cpid]
      end

      # Once it sends the signal sleep the child processes to give them time to tear down
      # and wait to see if the child processes are dead.
      # If the child process to kill it's still alive returns immediately so it's non blocking
      # then terminate the child process forcefully so it can exit and all child processes are tore down.

      sleep 5
      CHILD_PIDS.each do |cpid|
        begin
          Process.waitpid(cpid, :WNOHANG)
          Proces.kill[:INT, cpid]
        rescue Errno::ECHILD
        end
      end
    }
  end

  def set_title
    $PROGRAM_NAME = "MiniUnicorn Master"
  end

  def spawn_workers
    NUM_WORKERS.times do |num|
      CHILD_PIDS << fork {
        $PROGRAM_NAME = "MiniUnicorn Worker #{num}"
        trap_child_signals
        worker_loop
      }
    end
  end

  def trap_child_signals
    #Signal.trap(:INT) {
      #@should_exit = true
    #}
  end

  def load_app
    rackup_file = 'config.ru'
    @app, options = Rack::Builder.parse_file(rackup_file)
  end

  def worker_loop
    loop do
      connection, _ = @listener.accept

      # read = lazy read
      # it blocks until it gets EOF
      #
      # readpartial = greedy read

      raw_request = connection.readpartial(4096)

      parser = HTTPTools::Parser.new
      parser.on(:finish) do
        env = parser.env.merge!("rack.multiprocess" => true)
        status, header, body = @app.call(env)

        header["Connection"] = "close"
        connection.write HTTPTools::Builder.response(status, header)
        body.each {|chunk| connection.write chunk }
        body.close if body.respond_to?(:close)
      end

      parser << raw_request
      connection.close
    end
  end
end


# $:> ruby mini-unicorn.rb
# $:> echo foo | nc localhost 8080

server = MiniUnicorn.new
server.start

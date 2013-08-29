require 'socket'
require 'rack'
require 'rack/builder'

class MiniUnicorn
  NUM_WORKERS = 4
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
    NUM_WORKERS.times do |num|
      fork {
        $PROGRAM_NAME = "MiniUnicorn Worker #{num}"
        worker_loop
      }
    end
  end

  $PROGRAM_NAME = "MiniUnicorn Master"

  sleep

  def load_app
    rackup_file = 'config.ru'
    @app, options = Rack::Builder.parse_file(rackup_file)
  end

  def worker_loop
    loop do

      # parse HTTP
      # call the rack app
      # builde the response
      # parse the response

      connection, _ = @listener.accept
      connection.write(connection.read)
      connection.close
    end
  end
end


# $:> ruby mini-unicorn.rb
# $:> echo foo | nc localhost 8080

server = MiniUnicorn.new
server.start

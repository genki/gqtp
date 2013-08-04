# -*- coding: utf-8 -*-
# Example:
#
#  EM.run do
#    Fiber.new do
#      c = GQTP::Client.new :host => 'localhost', :port => 10041,
#        :connection => :eventmachine
#      c.send "status" do |head, body|
#        puts body
#      end
#      EM.stop
#    end.resume
#  end

require 'fiber'
require 'eventmachine'

module GQTP
  module Connection
    module Eventmachine
      class Request
        def initialize(data)
          @data = data
        end

        def wait
          @data
        end
      end

      class Socket < EM::Connection
        def self.open(host, port) EM.connect host, port, Socket end

        def post_init
          @in = ''.force_encoding('ASCII-8BIT')
          @out = ''.force_encoding('ASCII-8BIT')
          @closed = false
          @remote_closed = false
        end

        def receive_data(data) @in << data end
        def unbind; @remote_closed = true end

        def send(data = nil)
          raise IOError, "closed stream" if @closed
          raise Errno::EPIPE if @remote_closed
          @out << data if data
          loop do
            break true if @out.empty?
            if get_outbound_data_size > EM::FileStreamer::BackpressureLevel
              EM.next_tick{send}
              break false
            else
              len = [@out.bytesize, EM::FileStreamer::ChunkSize].min
              send_data @out.slice!(0, len)
            end
          end
        end

        def recv(len)
          raise IOError, "closed stream" if @closed
          em_sleep(0) until @in.bytesize >= len
          @in.slice! 0, len if @in.bytesize >= len
        end

        def em_sleep(secs)
          fiber = Fiber.current
          EM::Timer.new(secs){fiber.resume}
          Fiber.yield
        end

        def closed?
          if @remote_closed
            close
          end
          @closed
        end

        def close
          @closed = true
          EM.close_connection signature, true
        end
      end

      class Client
        attr_accessor :address, :port
        def initialize(options={})
          @options = options
          @address = options[:address] || "127.0.0.1"
          @port = options[:port] || 10041
          @socket = Socket.open(@address, @port)
        end

        def write(*chunks, &block)
          chunks.each do |chunk|
            @socket.send chunk
          end
          block.call if block
          Request.new nil
        end

        def read(size, &block)
          result = @socket.recv(size)
          block.call result if block
          Request.new result
        end

        def close
          @socket.close
        end
      end

      class Server
        attr_accessor :address, :port
        def initialize(options={})
          @options = options
          @address = options[:address] || "0.0.0.0"
          @port = options[:port] || 10041
        end

        def run
          EM.run do
            @signature = EM.start_server @address, @port, self, &block
          end
        end

        def shutdown
          EM.stop_server @signature
        end
      end
    end
  end
end

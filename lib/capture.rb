require "pcap"
require "logger"

module Capturing

  class Runner

    def initialize(exec)
      @exec = exec
      @pcaplet = Pcap::Capture.open_live(exec.device, exec.max_bytes, true, exec.timeout)
      @pcaplet.setfilter(Pcap::Filter.new("port #{exec.port} and tcp", @pcaplet))
    end

    def run!
      @pcaplet.each_packet do |packet|
        if packet.tcp? && packet.tcp_data_len > 0
          @exec.logger.debug "Handle message packets: #{packet}"
          begin
            on_packet packet.tcp_data
          rescue => e
            @exec.logger.error e
          end
        end
      end
    end

    def on_packet(data)
      raise NotImplementedError.new "on_packet(packet)"
    end

    def destroy!
      @pcaplet.close
    end
  end

  class PrintRunner < Runner
    require "fluent/engine"
    require "fluent/time"

    def initialize(e, writer:)
      super e
      @writer = writer
      @unpacker = Fluent::Engine.msgpack_factory.unpacker
      @time_formatter = Fluent::TimeFormatter.new("%Y-%m-%d %H:%M:%S %z", false, nil) # TODO support format
    end

    def on_packet(data)
      @unpacker.feed_each(data) do |msg|
        tag, entries = msg
        entries.each do |e|
          @writer.write(format_message(tag, e))
        end
      end
    end

    def format_message(tag, entry)
      time, record = entry
      "#{@time_formatter.format(time)} | tag=#{tag} msg=#{record.inspect}\n"
    end
  end

  class ForwardRunner < Runner
    require "socket"
    require "threadpool"

    def initialize(e, host:, port:, output:)
      super e
      @host = host
      @port = port
      @output = output
      @use_embed_fluentd = false # TODO support this mode

      start_embed_fluentd if @use_embed_fluentd
      @sock = new_socket_to_forward
      @messaging_thread_pool = ThreadPool.new(4) # TODO configurable
    end

    def on_packet(data)
      @messaging_thread_pool.process{ @sock.write data }
      @exec.logger.info "Forwarded message to #{@host}:#{@port}"
    end

    private
    def new_socket_to_forward
      max_retry = 10
      begin
        TCPSocket.new(@host, @port)
      rescue Errno::ECONNREFUSED
        raise if max_retry == 0
        sleep 1
        max_retry -= 1
        retry
      end
    end

    def start_embed_fluentd
      Thread.start {
        Dir.mktmpdir do |dir|
          conf = File.join(dir, "fluent.conf")
          output_file = File.join(dir, 'output')
          @exec.logger.info "Output message to '#{output_file}'" # TODO set file path
          File.write(conf, <<-EOF)
            <source>
              @type forward
              port #{@port}
            </source>
            <match **>
              @type file
              path #{@output}
              buffer_type memory
              append true
              flush_interval 0s
            </match>
          EOF
          FluentdEmbed.new(conf).boot
        end
      }
    end
  end

  class Exec
    attr_reader :device, :max_bytes, :timeout, :port

    DEFAULT_LOGGER ||= Logger.new(STDOUT)

    def initialize(device: "eth0", max_bytes: 1460, timeout: 1000, port: 24224, logger: nil)
      @device = device
      @max_bytes = max_bytes
      @timeout = timeout
      @port = port
      @logger = logger
    end

    def logger
      @logger.nil? ? DEFAULT_LOGGER : @logger
    end
  end

  class FluentdEmbed
    require "fluent/version"
    require "fluent/supervisor"

    def initialize(config_path)
      @opts = {
        config_path: config_path,
        plugin_dirs: [],
        log_level: 2,
        libs: [],
        suppress_repeated_stacktrace: true,
        use_v1_config: true,
        supervise: true,
        standalone_worker: true
      }
    end

    def boot
      Fluent::Supervisor.new(@opts).run_worker
    end
  end
end

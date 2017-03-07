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
      @time_formatter = Fluent::TimeFormatter.new("%Y-%m-%d %H:%M:%S %z", true, nil) # TODO support format
    end

    def on_packet(data)
      @unpacker.feed_each(data) do |msg|
        tag = msg[0]
        entries = msg[1]
        case entries
        when String
          option = msg[2]
          size = (option && option["size"]) || 0
          es_class = (option && option["compressed"] == "gzip") ? Fluent::CompressedMessagePackEventStream : Fluent::MessagePackEventStream
          es_class.new(entries, nil, size.to_i).each do |time, record|
            @writer.write(format_message(tag, [time, record]))
          end
        when Array
          entries.each do |e|
            @writer.write(format_message(tag, e))
          end
        else
          raise "Unsuooprted entry format '#{entry.class}'" # TODO
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

    def initialize(e, host:, port:, fluentd_config: nil)
      super e
      @host = host
      @port = port
      @fluentd_config = fluentd_config

      start_embed_fluentd(fluentd_config) unless fluentd_config.nil?
      @sock = new_socket_to_forward
      @messaging_thread_pool = ThreadPool.new(4) # TODO configurable
    end

    def on_packet(data)
      @messaging_thread_pool.process{ @sock.write data }
      @exec.logger.info "Forwarded message to #{@host}:#{@port}" unless @use_embed_fluentd
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

    def start_embed_fluentd(config_path)
      @exec.logger.info "Starting embed Fluentd config_path='#{config_path}'"
      Thread.start {
        begin
          FluentdEmbed.new(config_path).boot
        rescue => e
          # TODO stop immediately
          @exec.logger.error "Failed to start embed Fluentd (#{e.message})"
          raise e
        end
      }
    end
  end

  class Exec
    attr_reader :device, :max_bytes, :timeout, :port

    DEFAULT_LOGGER ||= Logger.new(STDOUT)

    def initialize(device: "eth0", max_bytes: 1048576, timeout: 1000, port: 24224, logger: nil)
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

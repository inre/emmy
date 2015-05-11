module Emmy
  class Runner
    include Singleton
    using EventObject
    events :parse

    RUBY     = Gem.ruby
    BIN_EMMY = "bin/emmy"

    attr_accessor :argv
    attr_accessor :env
    attr_accessor :config
    attr_accessor :action
    attr_accessor :option_parser

    def initialize
      @argv = ARGV
      @env  = ENV
      @config = EmmyHttp::Configuration.new
      @action = :start_server

      on :parse do
        parse_environment!
      end
      on :parse do
        option_parser.parse!(argv)
      end
      on :parse do
        defaults!
      end
      on :parse do
        update_rack_environment!
      end
    end

    def execute_bin_emmy
      return false unless File.file?(BIN_EMMY)
      exec RUBY, BIN_EMMY, *argv
      true
    end

    def parse_environment!
      config.environment = env['EMMY_ENV'] || env['RACK_ENV'] || 'development'
    end

    def update_rack_environment!
      ENV['RACK_ENV'] = config.environment
    end

    def option_parser
      @option_parser ||= OptionParser.new do |opts|
        opts.banner  = "Usage: emmy [options]"
        opts.separator "Options:"
        # configure
        opts.on("-e", "--environment ENV", "Specifies the execution environment",
                                          "Default: #{config.environment}") { |env| config.environment = env }
        opts.on("-p", "--port PORT",      "Runs Emmy on the specified port",
                                          "Default: #{config.url.port}")        { |port| config.url.port = port }
        opts.on("-a", "--address HOST",   "Binds Emmy to the specified host",
                                          "Default: #{config.url.host}")     { |address| config.url.host = address }
        opts.on("-b", "--backend [name]", "Backend name",
                                          "Default: backend")         { |name| config.backend = name }
        opts.on("-d", "--daemonize", "Runs server in the background") { @action = :daemonize_server }
        opts.on("-s", "--silence",   "Logging disabled")              { config.logging = false }
        # actions
        opts.on("-i", "--info",      "Shows server configuration") { @action = :show_configuration }
        opts.on("-c", "--console",   "Start a console")            { @action = :start_console }
        opts.on("-h", "--help",      "Display this help message")  { @action = :display_help }
        opts.on("-v", "--version",   "Display Emmy version.")      { @action = :display_version }
      end
    end

    def defaults!
      if Process.uid == 0
        config.user  = "worker"
        config.group = "worker"
      end

      config.pid  ||= "#{config.backend}.pid"
      config.log  ||= "#{config.backend}.log"
      if config.environment == "development"
        config.stdout = "#{config.backend}.stdout"
        config.stderr = config.stdout
      end
    end

    def run_action
      # Run parsers
      parse!
      # start action
      send(action)
      self
    end

    def daemonize_server
      Process.fork do
        Process.setsid
        exit if fork

        scope_pid(Process.pid) do |pid|
          puts pid
          File.umask(0000) # rw-rw-rw-
          bind_standard_streams
          start_server
        end
      end
    end

    def start_server
      load backend_file
    end

    def start_console
      if defined?(binding.pry)
        TOPLEVEL_BINDING.pry
      else
        require 'irb'
        require 'irb/completion'
        EmmyMachine.run_block do
          IRB.start
        end
      end
    end

    def show_configuration
      puts "Server configuration:"
      config.attributes.each do |name, value|
        value = "off" if value.nil?
        puts "  #{name}: #{value}"
      end
    end

    def display_help
      puts option_parser
    end

    def display_version
      puts Emmy::VERSION
    end

    def error(message)
      puts message
      exit
    end

    private

    def backend_file
      thin = (config.backend == 'backend') ? EmmyExtends::Thin::EMMY_BACKEND : nil rescue nil
      backends = [
        "#{Dir.getwd}/#{config.backend}.rb",
        "#{Dir.getwd}/config/#{config.backend}.rb",
        thin
      ].compact

      backends.each do |file|
        return file if File.readable_real?(file)
      end
      error "Can't find backend in #{backends.inspect} places."
    end

    def scope_pid(pid)
      FileUtils.mkdir_p(File.dirname(config.pid))
      File.open(config.pid, 'w') { |f| f.write(pid) }
      if block_given?
        yield pid
        delete_pid
      end
    end

    def delete_pid
      File.delete(config.pid)
    end

    def bind_standard_streams
      STDIN.reopen("/dev/null")
      STDOUT.reopen(config.stdout, "a")

      if config.stdout == config.stderr
        STDERR.reopen(STDOUT)
      else
        STDERR.reopen(config.stderr, "a")
      end
    end

    #<<<
  end
end

require 'colorize'
require 'highline'

module WithSymbol
  refine Symbol do
    def with(*args, &block)
      ->(caller, *rest) { caller.send(self, *rest, *args, &block) }
    end
  end
end

using WithSymbol

# commands
define_method(:commands) do
  {
    help: {
      command: :notice,
      description: "Print this usage notice"
    },
    version: {
      command: :version,
      description: "Print used version of Swarm"
    },
    ping: {
      command: :ping,
      description: "Check if connexions for each VM are well configured"
    },
    create: {
      command: :create_cluster,
      description: "Create cluster"
    },
    network: {
      command: :create_network,
      description: "Create Docker overlay network"
    },
    hostnames: {
      command: :set_hostnames,
      description: "Set node hostnames"
    },
    'config-docker': {
      command: :config_docker,
      description: "Configure the Docker daemon on each host"
    },
    test: {
      command: :test_cluster,
      description: "Run hello world on each Docker node using the Swarm manager"
    },
    'init-xp': {
      command: :init_nodes_for_xp,
      description: "Initialize nodes for experimental POC by getting repository"
    }
  }
end

commands.values.map(&:[].with(:command)).each do |command|
  file = "commands/#{command}"
  begin
    require_relative file
  rescue LoadError
    puts "WARN: file #{file}.rb not found".colorize(:red)
  end
end



# handle ARGS
notice if ARGV.empty?
until ARGV.empty? do
  arg = ARGV.shift

  if commands[arg.to_sym]
    params = []
    while !ARGV.empty? && commands[ARGV[0].to_sym].nil? do
      params << ARGV.shift
    end

    send(commands[arg.to_sym][:command], *params)
  else
    puts "#{arg} is not a valid command\n\n".colorize(:red)
    notice
    break
  end
end

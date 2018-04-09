define_method(:create_cluster) do |create = true|
  strategy = Settings.swarm.strategy

  if create
    puts "Create new Swarm cluster with strategy #{strategy.colorize(:red)}"
  else
    puts "Add nodes to Swarm cluster"
  end

  puts "Remove existing Swarm containers".colorize(:blue)

  threads = Node.all.map do |node|
    Thread.new do
      sleep rand(2)

      node_commands = [
        docker[:rm].call(Settings.node_localhost, '-f', 'swarm-node'),
        'sudo rm /etc/docker/key.json',
        'sudo service docker restart'
      ]

      ssh_exec(node.ip, node_commands)
    end
  end

  create && threads << Thread.new do
    manager_commands = [
      docker[:rm].call(localhost, '-f', 'swarm-manager'),
      # docker[:rm].call(Settings.node_localhost, '-f', 'swarm-node'),
      'sudo rm /etc/docker/key.json',
      'sudo service docker restart'
    ]
    ssh_exec(Node.manager.ip, manager_commands) if create
  end

  threads.each{ |thread| thread.join }

  if create
    puts "Create Consul key-value store".colorize(:blue)

    consul_create = [
      docker[:rm].call(localhost, '-f', 'consul'),
      docker[:run].call(localhost, "-d -p #{Settings.consul_port}:8500 -p 8300:8300 -p 8301:8301/tcp -p 8301:8301/udp -p 8302:8302/tcp -p 8302:8302/udp -p 8400:8400 -p 53:8600/tcp -p 53:8600/udp -h consul --name consul", 'progrium/consul', '-server -bootstrap')
    ]

    ssh_exec(Settings.consul_ip, consul_create)
    sleep 10
  end

  puts "Join nodes to cluster".colorize(:blue)

  Node.all.map do |node|
    sleep rand(2)

    Thread.new do
      node_commands = [
        swarm[:join].call(node.ip)
      ]
      ssh_exec(node.ip, node_commands)
    end
  end
  .each{ |thread| thread.join }

  puts "Instantiate manager".colorize(:blue)

  manager_commands = [
    swarm[:manage].call(Node.manager.ip, Settings.manager_docker_port, strategy)
  ]
  ssh_exec(Node.manager.ip, manager_commands) if create

  puts "Redefine networks created by Swarm".colorize(:blue)

  network_commands = Node.all.map do |node|
    opts = {
      driver: :bridge,
      subnet: "172.28.0.0/24",
      gateway: "172.28.0.1",
      "opt com.docker.network.bridge.enable_icc": false,
      "opt com.docker.network.bridge.enable_ip_masquerade": true,
      "opt com.docker.network.bridge.name": :docker_gwbridge
    }

    [
      docker[:network_rm].call(Settings.manager_localhost, "#{node.name}/docker_gwbridge"),
      docker[:network_create].call(Settings.manager_localhost, "#{node.name}/docker_gwbridge", opts)
    ]
  end.flatten.push(docker[:network_ls].call(Settings.manager_localhost))
  ssh_exec(Node.manager.ip, network_commands)

  puts "Check check check".colorize(:blue)

  manager_commands = [
    'echo "List nodes in Swarm cluster"',
    swarm[:list].call(),
    'echo "Call docker info on Swarm cluster manager"',
    docker[:info].call(Settings.manager_localhost)
  ]
  ssh_exec(Node.manager.ip, manager_commands)
end

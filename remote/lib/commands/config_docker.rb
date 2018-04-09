define_method(:config_docker) do
  puts 'Config Docker on all hosts'.colorize(:blue)

  (
    [Node.manager, Node.consul].map do |node|
      Thread.new do
        sleep rand(2)
        node_commands = [
          "sudo sed -i \"/ExecStart.*/c\\ExecStart=/usr/bin/docker daemon -H tcp://0.0.0.0:#{Settings.node_docker_port} -H unix:///var/run/docker.sock --bip 172.27.0.1/16 --label type=\\\"#{node.type}\\\"\" /lib/systemd/system/docker.service",
          'sudo systemctl daemon-reload',
          'sudo rm /etc/docker/key.json',
          'sudo service docker restart'
        ]

        ssh_exec(node.ip, node_commands)
      end
    end <<
    Node.all.map do |node|
      Thread.new do
        sleep rand(2)
        node_commands = [
          "sudo sed -i \"/ExecStart.*/c\\ExecStart=/usr/bin/docker daemon -H tcp://0.0.0.0:#{Settings.node_docker_port} -H unix:///var/run/docker.sock --bip 172.27.0.1/16 --cluster-store=consul://#{Settings.consul_ip}:#{Settings.consul_port} --cluster-advertise=#{node.network_if}:#{Settings.node_docker_port} --label type=\\\"#{node.type}\\\"\" /lib/systemd/system/docker.service",
          'sudo systemctl daemon-reload',
          'sudo rm /etc/docker/key.json',
          'sudo service docker restart'
        ]

        ssh_exec(node.ip, node_commands)
      end
    end
  ).each{ |thread| thread.join }
end

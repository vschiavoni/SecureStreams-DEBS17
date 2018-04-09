# Swarm docker commands
def localhost
  'localhost:2375'
end

def swarm
  {
    create: ->{ docker[:run].call(localhost, '--rm', Settings.swarm.image, 'create') },
    version: ->{ docker[:run].call(localhost, '--rm', Settings.swarm.image, '--version') },
    list: ->(){ docker[:run].call(localhost, '--rm', Settings.swarm.image, "list consul://#{Settings.consul_ip}:#{Settings.consul_port}") },
    join: ->(node){ docker[:run].call(Settings.node_localhost, '-d -p 2380:2375 -e DEBUG=true --name=swarm-node', Settings.swarm.image, "join --advertise=#{ip(node)}:#{Settings.node_docker_port} consul://#{Settings.consul_ip}:#{Settings.consul_port}") },
    manage: ->(manager, port, strategy){ docker[:run].call(localhost, "-d -p #{port}:2375 -e DEBUG=true --name=swarm-manager -h swarm", Settings.swarm.image, "manage --strategy #{strategy} --engine-failure-retry \"10\" -H :2375 --replication --advertise #{manager}:#{port} consul://#{Settings.consul_ip}:#{Settings.consul_port}") }
  }
end

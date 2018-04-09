# Docker commands
def docker
  {
    info: ->(host){ "docker -H tcp://#{host} info" },
    ps: ->(host, opts){ "docker -H tcp://#{host} ps #{opts}" },
    pull: ->(host, image){ "docker -H tcp://#{host} pull #{image}" },
    logs: ->(host, opts, container){ "docker -H tcp://#{host} logs #{opts} #{container}" },
    run: ->(host, opts, image, args=nil){ "docker -H tcp://#{host} run #{opts} #{image} #{args}" },
    create: ->(host, opts, image, args=nil){ "docker -H tcp://#{host} create #{opts} #{image} #{args}" },
    rm: ->(host, opts, container){ "docker -H tcp://#{host} rm #{opts} #{container}" },
    start: ->(host, opts, container){ "docker -H tcp://#{host} start #{opts} #{container}" },
    stop: ->(host, opts, container){ "docker -H tcp://#{host} stop #{opts} #{container}" },
    login: ->(host){ "docker -H tcp://#{host} login" },
    inspect: ->(host, opts){ "docker -H tcp://#{host} inspect #{opts}" },
    network_ls: ->(host){ "docker -H tcp://#{host} network ls" },
    network_rm: ->(host, network){ "docker -H tcp://#{host} network rm #{network}" },
    network_create: ->(host, network, opts={}){ "docker -H tcp://#{host} network create #{opts.map{ |o,v| "--#{o}=#{v}"}.join(" ")} #{network}" }
  }
end

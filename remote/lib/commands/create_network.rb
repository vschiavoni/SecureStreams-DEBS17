define_method(:create_network) do
  puts "Create overlay network '#{Settings.network_name}' on cluster"

  network_opts = {
    driver: :overlay
  }

  commands = [
    docker[:network_create].call(
      Settings.manager_localhost,
      Settings.network_name,
      network_opts
      ),
    docker[:network_ls].call(Settings.manager_localhost)
  ]

  ssh_exec(Node.manager.ip, commands)
end

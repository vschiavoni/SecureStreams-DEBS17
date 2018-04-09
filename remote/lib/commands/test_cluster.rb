define_method(:test_cluster) do
  puts 'Test each node by running hello-world through the manager'.colorize(:blue)

  Node.all.each do |node|
    run_hello_world_command = docker[:run].call(Settings.manager_localhost, "-it --rm -e constraint:node==#{node.name}", 'hello-world')

    puts "Run hello-world on node #{node.name}:".colorize(:blue)
    ssh_exec(Node.manager.ip, run_hello_world_command, pty: true)
  end
end

define_method(:ping) do
  puts 'Ping all hosts'.colorize(:blue)

  (Node.all + [Node.manager, Node.consul]).map do |node|
    sleep rand(2)
    Thread.new do
      ssh_exec(node.ip, "echo 'PONG from host #{node.ip}'")
    end
  end
  .each{ |thread| thread.join }
end

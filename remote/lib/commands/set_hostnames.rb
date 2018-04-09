define_method(:set_hostnames) do
  set_hostname = ->(name){
    [
      "sudo hostname #{name}",
      "sudo sed -i \"/127\\.0\\.1\\.1.*/c\\127.0.1.1\\t#{name}\" /etc/hosts",
      "sudo -- sh -c 'echo \"#{name}\" > /etc/hostname'"
    ]
  }

  if HighLine.new.ask("You will reset hostname of each host. Do you confirm? [y/n]") == 'y'
    Node.all.push(Node.manager).each do |node|
      ssh_exec(node.ip, set_hostname.call(node.name))
    end
  end
end

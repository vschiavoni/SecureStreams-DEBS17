define_method(:export_pkey) do |filename = Settings.ssh.public_key_file|
  raise "File #{filename} not found" unless File.file?(filename)

  public_key = File.open(filename).read
  puts "Your public key is: #{public_key.colorize(:yellow)}"

  if HighLine.new.ask("You will add your public key on all machines. Do you confirm? [y/n]") == 'y'
    Node.all.each do |node|
      send_public_key(node.ip, public_key)
    end
    puts 'Done.'
  end
end

define_method(:notice) do
  puts "Welcome to the remote manager\n\n"
  version
  puts "Use one or several (you can chain them) of the following commands:\n\n"

  cli = ENV['_'].include?('./remote.rb')
  size = (cli ? commands.keys.map(&:size) : commands.map{ |c| c.last[:command].size }).max

  commands.each do |key, value|
    command = cli ? key : value[:command]
    puts "- #{command}#{"\t" * ((size + 5) / 8 - (command.size + 2) / 8)} #{value[:description]}"
  end

  puts "\nFor example:\t #{$0} ping config_docker create test network"
end

require 'socket'
require 'timeout'
require 'net/ssh'
require 'net/ssh/proxy/command'
require 'net/ssh/gateway'
require 'ruby_expect'
require 'colorize'

URL_REGEX = /^((\w+):\/\/)?((\/|\.|[a-z0-9])+)(:(\d+))?$/

# SSH command
proxy_options = Settings.ssh[:proxy] && "ssh -i #{Settings.ssh.identity_file} #{Settings.ssh.proxy['user']}@#{Settings.ssh.proxy['host']} -W \"%h:%p\""
proxy = proxy_options && Net::SSH::Proxy::Command.new(proxy_options)

{
  protocol: ->(address) { address.match(URL_REGEX)[2] },
  ip: ->(address) { address.match(URL_REGEX)[3] },
  port: ->(address) { address.match(URL_REGEX)[6] || 22 },
  ssh_exec: ->(address, commands, opts={}) {
    command = [commands].flatten.join(";\\\n")
    puts "\n[#{"Run on host".colorize(:yellow)} (#{address.colorize(:blue)})] - #{Time.now.to_s.colorize(:magenta)}\n\t#{command.colorize(:green)}\n\n"
    config = {
      port: port(address),
      keys: [Settings.ssh.identity_file],
      forward_agent: true
    }
    config[:proxy] = proxy if proxy

    Net::SSH.start(
      ip(address),
      Settings.ssh.user,
      config
    ) do |ssh|
      if opts[:pty]
        ssh.open_channel do |channel|
          channel.request_pty do |ch, success|
            channel.exec(command) do |ch, success|
              abort "could not execute command".colorize(:red) unless success
              puts "Received from remote:".colorize(:yellow)

              channel.on_data do |ch, data|
                puts data.colorize(:white)
                channel.send_data(opts[:interactive] && gets || "\n")
              end

              channel.on_extended_data do |ch, type, data|
                puts data.colorize(:white)
              end

              channel.on_close do |ch|
                puts "Connection closed".colorize(:yellow)
              end
            end
          end
        end

        ssh.loop
      else
        response = ssh.exec!(command).colorize(:light_yellow)
        puts "\n[#{"Response from host".colorize(:yellow)} (#{address.colorize(:blue)})] - #{Time.now.to_s.colorize(:magenta)}\n\n" + response unless response.empty?
        response
      end
    end
  },
  is_gateway_open?: ->(port) {
    begin
      Timeout::timeout(1) do
        begin
          s = TCPSocket.new('localhost', port)
          s.close
          return true
        rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
          return false
        end
      end
    rescue Timeout::Error
      puts "Timeout checking if tunnel is open for port #{port}"
    end

    return false
  },
  open_tunnel: ->(host, local_port, remote_port=nil) {
    if is_gateway_open?(local_port)
      puts "Gateway open"
      false
    else
      remote_port ||= local_port
      puts "ssh -fN -i #{Settings.ssh.identity_file} #{Settings.ssh.proxy['user']}@#{Settings.ssh.proxy['host']} -L #{local_port}:#{host}:#{remote_port}"
      Thread.new { `ssh -fN -i #{Settings.ssh.identity_file} #{Settings.ssh.proxy['user']}@#{Settings.ssh.proxy['host']} -L #{local_port}:#{host}:#{remote_port}` }
    end
  },
  open_gateway: ->(host, local_port, remote_port=nil) {
    if is_gateway_open?(local_port)
      return false
    else
      remote_port ||= local_port
      gateway = Net::SSH::Gateway.new(
        Settings.ssh.proxy['host'],
        Settings.ssh.proxy['user'],
        keys: [Settings.ssh.identity_file]
       )
      return gateway.open(host, remote_port, local_port)
    end
  },
  send_public_key: ->(host, pubkey) {
    puts "Exporting key on #{host.colorize(:blue)}..."
    exp = RubyExpect::Expect.spawn("ssh #{Settings.ssh.user}@#{host}")
    exp.procedure do
      retval = 0
      while (retval != 2)
        retval = any do
          expect /Are you sure you want to continue connecting \(yes\/no\)\?/ do
            send 'yes'
          end

          expect /password:\s*$/ do
            send 'ubuntu'
          end

          expect /\$\s*$/ do
            send "echo '#{pubkey}' >> /home/#{Settings.ssh.user}/.ssh/authorized_keys"
          end
        end
      end

      # Expect each of the following
      each do
        expect /\$\s+$/ do # shell prompt
          send 'exit'
        end
      end
    end
  }
}.each do |key,block|
  define_method(key, &block)
end

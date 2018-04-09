define_method(:init_nodes_for_xp) do |branch = 'master'|
  raise "Configuration for POC is missing" unless Settings.poc
  raise "Working directory for POC is missing" unless Settings.poc.working_dir
  raise "Remote repository for POC is missing" unless Settings.poc.remote_repo
  raise "Project name for POC is missing" unless Settings.poc.project_name
  raise "Experiment path for POC is missing" unless Settings.poc.experiment_path


  commands = [
    "rm -rfv #{Settings.poc.working_dir}",
    'ssh-keyscan -H github.com >> ~/.ssh/known_hosts',
    'ssh -T git@github.com',
    "mkdir -p #{Settings.poc.working_dir}",
    "git clone #{Settings.poc.remote_repo} #{Settings.poc.working_dir}/#{Settings.poc.project_name}",
    "cd #{Settings.poc.working_dir}/#{Settings.poc.project_name}",
    "git fetch",
    "git checkout #{branch}",
    "git pull",
    "cd #{Settings.poc.working_dir}/#{Settings.poc.project_name}/#{Settings.poc.experiment_path}/test",
    'cp -f ../data-stream.lua data-stream.lua',
    'cp -f ../map-csv-to-event.lua map-csv-to-event.lua',
    'cp -f ../filter-event.lua filter-event.lua',
    'cp -f ../reduce-events.lua reduce-events.lua',
    'cp -f ../print-results.lua print-results.lua',
    'cp -f ../router.lua router.lua',
    "cd #{Settings.poc.working_dir}/#{Settings.poc.project_name}/#{Settings.poc.experiment_path}/test-sgx",
    'cp -f ../data-stream.lua data-stream.lua',
    'cp -f ../sgx-map-csv-to-event.lua sgx-map-csv-to-event.lua',
    'cp -f ../sgx-filter-event.lua sgx-filter-event.lua',
    'cp -f ../sgx-reduce-events.lua sgx-reduce-events.lua',
    'cp -f ../print-results.lua print-results.lua',
    'cp -f ../router.lua router.lua'
  ]

  Node.all.map do |node|
    sleep rand(2)
    Thread.new do
      ssh_exec(node.ip, commands)
    end
  end
  .each{ |thread| thread.join }

  data_files = {
    data1: '2005',
    data2: '2006',
    data3: '2007',
    data4: '2008'
  }

  data_files.map do |data,file|
    Node.with_roles(data).map do |node|
      Thread.new do
        commands = [
          'cd /home/ubuntu/zmqrxlua/zmqrxlua-poc/experiment/test/data',
          "wget http://stat-computing.org/dataexpo/2009/#{file}.csv.bz2 && bzip2 -d #{file}.csv.bz2"
        ]

        ssh_exec(node.ip, commands)
      end
    end
  end
  .flatten
  .each{ |thread| thread.join }
end

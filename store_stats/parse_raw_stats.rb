#!/usr/bin/env ruby

require 'json'
require 'date'

# set env INPUT for files path this one gonna be process recursively
# to convert all files matching extension .json.log
INPUT_DIR = "#{ENV['INPUT'] || 'test_datas'}/**"
# change the following it you want to retrieve throughputs from another itf
NETWORK_IF = 'eth0'


Dir.glob("#{INPUT_DIR}/*.json.log").each do |input_filename|
  output_filename = input_filename.gsub(/\.json\.log/, '.dat')
  previous_datas = {}
  cumulative_datas = { rx: 0, tx: 0 }

  File.open(output_filename, 'w') do |output_file|
    output_file.puts '#timestamp(s) cpu_usage(ticks) memory_usage(bytes) rx(bytes) tx(bytes)'

    File.readlines(input_filename).each do |line|
      json = JSON.parse(line)

      # CPU percentage calcul
      cpu_delta = json['cpu_stats']['cpu_usage']['total_usage'].to_f - json['precpu_stats']['cpu_usage']['total_usage'].to_f
      system_delta = json['cpu_stats']['system_cpu_usage'].to_f - json['precpu_stats']['system_cpu_usage'].to_f

      datas = {
        timestamp: DateTime.parse(json['read']).to_time.to_i,
        cpu_usage: cpu_delta > 0 && system_delta > 0 && ((cpu_delta / system_delta) * json['cpu_stats']['cpu_usage']['percpu_usage'].size * 100).round(2) || 0,
        memory_usage: json['memory_stats']['usage'],
        rx: json['networks'][NETWORK_IF]['rx_bytes'] - cumulative_datas[:rx],
        tx: json['networks'][NETWORK_IF]['tx_bytes'] - cumulative_datas[:tx]
      }

      if previous_datas[:timestamp] == datas[:timestamp]
        previous_datas = {
          timestamp: datas[:timestamp],
          cpu_usage: previous_datas[:cpu_usage] + datas[:cpu_usage],
          memory_usage: (previous_datas[:memory_usage] + datas[:memory_usage]) / 2,
          rx: previous_datas[:rx] + datas[:rx],
          tx: previous_datas[:tx] + datas[:tx]
        }
      else
        output_file.puts previous_datas.values.join(' ') unless previous_datas.empty?
        previous_datas = datas
      end

      cumulative_datas = {
        rx: cumulative_datas[:rx] + datas[:rx],
        tx: cumulative_datas[:tx] + datas[:tx]
      }
    end

    output_file.puts previous_datas.values.join(' ')
  end
end

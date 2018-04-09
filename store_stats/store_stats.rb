#!/usr/bin/env ruby

require 'docker'

OUTPUT_DIR = "output/#{Time.now.strftime("%Y%m%d%H%M%S")}"
ERROR_LOGS = "#{OUTPUT_DIR}/errors.log"
DOCKER_URL = "tcp://0.0.0.0:2381"

# containers = {} # { 'id': 'name', ... }

Docker.url = DOCKER_URL

# def store_logs_from_containers(containers_hash)
#   containers_hash.map do |id,name|
#     store_logs_from_container(id, "#{OUTPUT_DIR}/stats-#{name}.json")
#   end
# end
#
# def running_containers_hash
#   Docker::Container.all.map do |c|
#     [c.id, c.info["Names"].first.split('/').last]
#   end.to_h
# end
#
# def new_containers_hash
#   running_containers_hash.reject do |k,v|
#     containers.keys.include? k
#   end
# end


FileUtils.mkdir_p OUTPUT_DIR

pids = []

def store_logs_from_container(container_id, output)
  spawn({}, "curl -sSN http://0.0.0.0:2381/containers/#{container_id}/stats", out: output, err: ERROR_LOGS)
end

Signal.trap('TERM') do
  pids.each do |pid|
    Process.kill('TERM', pid)
  end
  exit
end

begin
  Docker::Event.stream do |event|
    if event.status == 'create'
      output = "#{OUTPUT_DIR}/stats-#{event.actor.attributes["name"]}.json.log"
      pids << store_logs_from_container(event.id, output)
    end
  end

rescue Docker::Error::TimeoutError
  retry
end

require 'yaml'

module DeepMergeHash
  refine Hash do
    def deep_merge(second)
        merger = proc { |key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }
        self.merge(second, &merger)
    end
  end
end

using DeepMergeHash

class Settings
  DEFAULT_OPTS = {
    'cluster' => {
      'manager_docker_port' => '2381',
      'node_docker_port' => '2375',
      'consul_port' => '8500',
      'network_name' => 'default_network'
    },
    'swarm' => {
      'image' => 'swarm:1.2.5',
      'strategy' => 'spread'
    }
  }

  def self.create_section(name, settings)
    self.class.instance_eval do
      define_method(name) do
        settings
      end

      settings.each do |key, value|
        next unless key.is_a? String

        self.send(name).define_singleton_method(key) do
          value.freeze
        end
      end
    end
  end

  begin
    @@settings = DEFAULT_OPTS.deep_merge(YAML::load_file('config.yml'))
  rescue Exception => e
    raise "Something is wrong with your config.yml file: #{e.message}"
  end

  @@settings.each do |key, value|
    create_section(key, value || [])
  end

  # add methods for nodes
  self.cluster.nodes.each do |node|
    [:ip, :name, :role, :roles, :network_if, :type].each do |attribute|
      node.define_singleton_method(attribute) { node[attribute.to_s] }
    end
  end

  self.define_singleton_method(:manager) { self.cluster.manager }
  self.define_singleton_method(:manager_docker_port) { self.cluster.manager_docker_port }
  self.define_singleton_method(:node_docker_port) { self.cluster.node_docker_port }
  self.define_singleton_method(:manager_localhost) { "localhost:#{manager_docker_port}" }
  self.define_singleton_method(:node_localhost) { "localhost:#{node_docker_port}" }
  self.define_singleton_method(:consul_ip) { self.cluster.consul_ip }
  self.define_singleton_method(:consul_port) { self.cluster.consul_port }
  self.define_singleton_method(:network_name) { self.cluster.network_name }
  self.define_singleton_method(:nodes) { self.cluster.nodes }
end

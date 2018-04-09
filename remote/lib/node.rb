require_relative 'settings'

class Node
  attr_accessor :ip, :name, :roles, :type, :network_if

  def initialize(ip:, name:, roles:, type:, network_if:)
    @ip = ip
    @name = name
    @roles = roles
    @type = type
    @network_if = network_if
  end

  @@nodes = Settings.nodes.map do |node|
    self.new(
      ip: node.ip,
      name: node.name,
      roles: [node.role || node.roles].flatten.compact.map(&:to_sym),
      type: node.type,
      network_if: node.network_if
    )
  end

  def self.all
    @@nodes
  end

  def self.with_roles(*roles)
    @@nodes.reject { |n| (n.roles & roles.map(&:to_sym)).empty? }
  end

  def self.without_roles(*roles)
    @@nodes.select { |n| (n.roles & roles.map(&:to_sym)).empty? }
  end

  def self.manager
    self.new(ip: Settings.manager, name: 'manager', roles: [:manager], type: :manager, network_if: nil)
  end

  def self.consul
    self.new(ip: Settings.consul_ip, name: 'consul', roles: [:consul], type: :consul, network_if: nil)
  end

  def sgx?
    @roles.include?(:sgx)
  end
end

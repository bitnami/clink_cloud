require 'bundler/setup'
require 'clink_cloud'
require 'securerandom'
require 'pry'

# create a client
client = ClinkCloud::Client.new(username: ARGV.shift, password: ARGV.shift)

"List all servers running"
# servers = client.servers.all

"List out available data centers"
dcs = client.data_centers.all
# dcs.each { |dc| puts dc.name, dc.id }

#
# Data center calls
#
# dc = client.data_centers.find(id: 'de1')
# caps = client.data_centers.get_deployment_capabilities(id: 'de1')
# bcaps = client.data_centers.get_bare_deployment_capabilities(id: 'de1')

#
# Group calls
#
# Need to do an individual fetch to find the group_id
#
# client.groups.find(id: '')
# client.groups.defaults(id: '')

#
# Let's always use canada for testing
#
dc = client.data_centers.find(id: 'ca1')
defs = client.groups.defaults(id: dc.group_id)
dc_group = client.groups.find(id: dc.group_id)
puts "root group #{dc_group.id}"
template_id = client.data_centers.get_deployment_capabilities(id: dc.id)['templates'].first['name']
# TODO: need a better metric for what to do here
launch_group_id = dc_group.groups.find { |gr| gr['name'] == "Default Group" }['id']
puts "launch group #{launch_group_id}"
puts "data center root group #{dc_group.id}"
server_name = "test#{SecureRandom.hex(1)}"
puts "server name #{server_name}"

# do we already have a launchpad group?
g_name = 'bitnami-launchpad-group'
already_group = nil
dc_group.groups.each do |g|
  puts g['name']

  if g['name'] == g_name
    already_group = true
    break
  end
end

#
# Create a new group to use for launching vms in
#
unless already_group
  puts "no group called #{g_name}"
  group = ClinkCloud::Group.new(
    name: 'bitnami-launchpad-group',
    description: 'A brief description',
    parentGroupId: dc.group_id
  )

  group = client.groups.create(group)
  puts "created a group with id #{group.id}"
end

#
# Server operations
#
# LET'S CREATE A SERVER!!
server = ClinkCloud::Server.new(
  name: server_name,
  # launch in the first dc in the list
  groupId: (group && group.id) || launch_group_id,
  sourceServerId: template_id,
  cpu: '1',
  memoryGB: '1',
  type: 'standard'
)


def wait_for(client, status_id)
  tries = 0

  loop do
    status = client.statuses.find(id: status_id)
    puts status
    sleep 5 && tries += 1
    break if status['status'] == 'succeeded' || tries > 48
  end

  puts "finished waiting for #{status_id}"
end

# actually creating
# server = client.servers.create(server)
# wait_for(client, server['status_id'])

# Clean up code

# remove all servers
launch_group = client.groups.find(id: launch_group_id)
sobjs = launch_group.servers(client)
sid = launch_group.find_server_id(name: server_name, dc_id: dc.id, account_alias: client.alias)

binding.pry
return

# launch_group.servers.each do |id|
#   s = client.servers.destroy(id: id)
#   binding.pry
# end

# remove all groups
dc_group.groups.each do |g|
  next unless g['name'] == g_name
  puts "deleting group #{g['id']}"
  client.groups.delete(id: g['id'])
end

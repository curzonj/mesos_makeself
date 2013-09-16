
## This file needs to be kept in sync with .chef/knife.rb

log_level                :debug
log_location             STDOUT

base = File.expand_path('../', __FILE__)
Chef::Config[:chef_root] = base

cookbook_path [ File.join(base, "cookbooks"), File.join(base, "tmp/vendored_cookbooks") ]

data_bag_path   File.join(base,   'data_bags')
role_path       File.join(base,   'roles')
json_attribs File.join(base, 'node.json') 

file_cache_path '/tmp/chef/cache'
cache_options :path => '/tmp/chef/cache/run'

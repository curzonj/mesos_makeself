url = "https://data.attstorage.com/jc816a/packages/mesos_0.14.0-3ubuntu13.04_amd64.deb"
package = File.basename(url)
package_path = "#{Chef::Config[:file_cache_path]}/#{package}"

remote_file package_path do
  source  url
end

dpkg_package package_path do
  action :install
end

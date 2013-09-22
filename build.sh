#!/bin/bash

set -e
set -x

export LC_ALL=C

cat > /etc/apt/sources.list <<EOS
deb http://archive.ubuntu.com/ubuntu/ raring main restricted universe
deb http://archive.ubuntu.com/ubuntu/ raring-updates main restricted universe
deb http://archive.ubuntu.com/ubuntu/ raring-security main restricted
EOS

apt-get update
apt-get --no-install-recommends -y install wget runit

# Because runit package gets started on install
service runsvdir stop || true

# This fails on dependencies
dpkg -i mesos_0.14.0-rc3-1_amd64.deb || true

apt-get install -f -y

dpkg -i mesos_0.14.0-rc3-1_amd64.deb


mkdir -p /service/mesos

## runit service script
cat > /service/mesos/run <<"EOS"
#!/bin/bash
exec $(cat /run/cmdline) 2>&1
EOS
chmod +x /service/mesos/run

mkdir -p /service/mesos/log
mkdir -p /var/log/mesos

## runit logging script
# TODO change to remote syslogging and configure destination with cmdline
# options to the run.sh script. We also need forward zookeeper.out to
# remote logging.
cat > /service/mesos/log/run <<"EOS"
#!/bin/bash

exec svlogd -t /var/log/mesos
EOS

chmod +x /service/mesos/log/run

apt-get -y clean

cp run.sh cleanup.sh /
chmod +x /run.sh /cleanup.sh

echo -n "./run.sh" > /command_line

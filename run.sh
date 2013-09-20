#!/bin/sh
# We use sh instead of bash to be more portable

set -e
set -x

# Makeself uses a 077 umask by default
umask 022

NAME=mesos

# NOTE this script runs in the wider context, the chroot
# doesnt' happen until runit is started on the last line.

echo "$@" > run/cmdline

# makeself puts mode 700 on this directory by default which causes
# problems for running things as non root users
chmod 755 .

cp /etc/resolv.conf etc/

# The cgroup makes it easy to keep track of spawned processes
MYSELF=$$
CGROUP=/sys/fs/cgroup/cpu/$NAME_$MYSELF

if [ -d /sys/fs/cgroup/cpu ]; then
  mkdir $CGROUP
  echo 0 > $CGROUP/tasks
fi

# Makeself tarball doesn't seem to respect ownership even as root
chown -R nobody:nogroup run
chown -R nobody:nogroup var/log/mesos

SOURCE_DIR=`pwd`
trap "$SOURCE_DIR/cleanup.sh $MYSELF $CGROUP" 0 1 2 3 13 15
mount -t proc proc ./proc

# Don't `exec` this because we need our traps to function
chroot ./ runsvdir -P /service

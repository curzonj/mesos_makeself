#!/bin/sh

set -x

MYSELF=$$
PARENT=$1
CGROUP=$2

umount ./proc

if [ -d $CGROUP ]; then
  kill -9 $(cat $CGROUP/tasks | grep -v $MYSELF | grep -v $PARENT)
  # NOTE We can't actually cleanup the cgroup itself because we belong to it
  # so it's busy. You can't remove a cgroup until it's empty.
fi


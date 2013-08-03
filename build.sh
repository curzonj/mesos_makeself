#!/bin/sh

## TODO should we use debootstrap for this?

ARCH=i386
CORE_VERSION=13.04
CORE_URL=http://cdimage.ubuntu.com/ubuntu-core/releases/$CORE_VERSION/release/ubuntu-core-$CORE_VERSION-core-$ARCH.tar.gz
CORE_TGZ=$(basename $CORE_URL)
SUDO=
export LC_ALL=C

# We'll be running this in busybox initially that doesn't have sudo
# but our dev box is ubuntu which does have sudo.
if which sudo; then
  SUDO=$(which sudo)
fi

if [ "$1" != "inner_shell" ]; then
  BUILD_DIR=$1
  if [ -z $BUILD_DIR ]; then
    BUILD_DIR=$(mktemp -d /tmp/mesos.XXXXXXXXXX)
  fi

  echo "Build directory is: $BUILD_DIR"

  [ -f $CORE_TGZ ] || wget --quiet $CORE_URL
  $SUDO tar -xf $CORE_TGZ -C $BUILD_DIR

  $SUDO cp /etc/resolv.conf $BUILD_DIR/etc/

  if [ -d debs ]; then
    $SUDO cp debs/*.deb $BUILD_DIR/var/cache/apt/archives/
  fi
    
  mount -t proc proc $BUILD_DIR/proc
  trap "umount $BUILD_DIR/proc" 0 1 2 3 13 15

  $SUDO chroot $BUILD_DIR /bin/bash -s -- inner_shell < $0
  exit_code=$?

  mkdir -p debs
  cp $BUILD_DIR/var/cache/apt/archives/*.deb ./debs/

  echo "Build directory is: $BUILD_DIR"
  echo "Exit code of the inner shell was: $exit_code"
  exit $exit_code
fi

set -e
set -x


apt-get update
apt-get -y --no-install-recommends install build-essential python python-dev libcppunit-dev openjdk-7-jdk openjdk-7-jre-headless wget

cd /tmp

wget http://www.carfab.com/apachesoftware/incubator/mesos/mesos-0.12.0-incubating/mesos-0.12.0-incubating.tar.gz
tar xf mesos-0.12.0-incubating.tar.gz
cd mesos*
./configure
make


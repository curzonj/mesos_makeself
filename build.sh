#!/bin/bash

set -e
set -x

CORE_ARCH=amd64
CORE_VERSION=13.04
CORE_URL=http://cdimage.ubuntu.com/ubuntu-core/releases/$CORE_VERSION/release/ubuntu-core-$CORE_VERSION-core-$CORE_ARCH.tar.gz
CORE_TGZ=$(basename $CORE_URL)

case $CORE_ARCH in
  amd64)
    OTHER_ARCH=x86_64
    ;;
  *)
    OTHER_ARCH=i386
    ;;
esac

CHEF_URL=https://opscode-omnibus-packages.s3.amazonaws.com/ubuntu/$CORE_VERSION/$OTHER_ARCH/chef_11.6.0-1.ubuntu.13.04_$CORE_ARCH.deb
CHEF_FILE=$(basename $CHEF_URL)

if [ $(id -u) != '0' ]; then
  exec sudo $0 $@
fi

export LC_ALL=C

if [ "$1" != "inner_shell" ]; then
  MAKESELF_URL=https://github.com/megastep/makeself/archive/master.tar.gz
  MAKESELF_FILE=$(basename $MAKESELF_URL)
  MAKESELF_DIR=makeself-master

  [ -f $MAKESELF_FILE ] || wget $MAKESELF_URL
  [ -d $MAKESELF_DIR ] || tar xf $MAKESELF_FILE

  if ! which berks; then
    apt-get update
    apt-get -y install build-essential libxml2-dev libxslt-dev
    apt-get -y --no-install-recommends install ruby1.9.3 ruby1.9.1-dev
  fi

  # TODO should we use debootstrap for this?
  # https://wiki.ubuntu.com/DebootstrapChroot
  BUILD_DIR=$1
  if [ -z $BUILD_DIR ]; then
    BUILD_DIR=$(mktemp -d /tmp/chef_container.XXXXXXXXXX)
  fi

  echo "Build directory is: $BUILD_DIR"

  [ -f $CORE_TGZ ] || wget $CORE_URL
  tar -xf $CORE_TGZ -C $BUILD_DIR

  [ -f $CHEF_FILE ] || wget $CHEF_URL

  cp /etc/resolv.conf $BUILD_DIR/etc/
  cp $CHEF_FILE $BUILD_DIR/tmp

  if [ -d debs ]; then
    # This is so huge it just clears the scrollback
    # buffer
    set +x
    cp debs/*.deb $BUILD_DIR/var/cache/apt/archives/
    set -x
  fi

  (
    cd /vagrant
    berks install -p $BUILD_DIR/tmp/chef/vendored_cookbooks
  )

  mkdir -p $BUILD_DIR/tmp/chef
  for i in node.json chef_solo.rb data_bags roles cookbooks; do
    if [ -e /vagrant/$i ]; then
      cp -a /vagrant/$i $BUILD_DIR/tmp/chef/
    fi
  done
    
  mount -t proc proc $BUILD_DIR/proc
  trap "umount $BUILD_DIR/proc" 0 1 2 3 13 15

  # We want to trap inner_shell failures
  set +e

  chroot $BUILD_DIR /bin/bash -s -- inner_shell < $0
  exit_code=$?

  set -e

  mkdir -p debs
  # This is so huge it just clears the scrollback
  # buffer
  set +x
  cp $BUILD_DIR/var/cache/apt/archives/*.deb ./debs/
  set -x

  echo "Build directory is: $BUILD_DIR"
  echo "Exit code of the inner shell was: $exit_code"
  exit $exit_code
fi

unset HOME

dpkg -i /tmp/$CHEF_FILE

/opt/chef/bin/chef-solo -c /tmp/chef/chef_solo.rb -l debug

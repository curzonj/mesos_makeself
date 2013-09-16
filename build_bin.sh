#!/bin/bash

set -e
set -x

if [ $(id -u) != '0' ]; then
  exec sudo $0 $@
fi

# TODO these need to be the same as CORE_VERSION in chroot.sh
CORE_VERSION=13.04
CORE_ARCH=amd64
OTHER_ARCH=x86_64

CHEF_URL=https://opscode-omnibus-packages.s3.amazonaws.com/ubuntu/$CORE_VERSION/$OTHER_ARCH/chef_11.6.0-1.ubuntu.13.04_$CORE_ARCH.deb
CHEF_FILE=$(basename $CHEF_URL)

[ -f $CHEF_FILE ] || wget -O$CHEF_FILE $CHEF_URL

MAKESELF_URL=https://github.com/megastep/makeself/archive/master.tar.gz
MAKESELF_FILE=makeself.tar.gz
MAKESELF_DIR=makeself-master

[ -f $MAKESELF_FILE ] || wget -O${MAKESELF_FILE} $MAKESELF_URL
[ -d $MAKESELF_DIR ] || tar xf $MAKESELF_FILE

if ! which berks; then
  apt-get update
  apt-get -y install build-essential libxml2-dev libxslt-dev
  apt-get -y --no-install-recommends install ruby1.9.1 ruby1.9.1-dev
  gem install berkshelf
fi

mkdir -p tmp
berks install -p tmp/vendored_cookbooks

./chroot.sh $@

OPTS=--nox11

if [ -f package.lsm ]; then
  OPTS="$OPTS --lsm package.lsm"
fi

rm -f package.bin
$MAKESELF_DIR/makeself.sh $OPTS $BUILD_DIR package.bin "Container" chroot ./ env -i /run.sh

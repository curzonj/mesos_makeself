#!/bin/bash

set -e
set -x

CORE_ARCH=amd64
CORE_VERSION=13.04
CORE_URL=http://cdimage.ubuntu.com/ubuntu-core/releases/$CORE_VERSION/release/ubuntu-core-$CORE_VERSION-core-$CORE_ARCH.tar.gz
CORE_TGZ=$(basename $CORE_URL)
CHEF_DIR=/tmp/chef
SOURCE_DIR=/vagrant

if [ ! -d $SOURCE_DIR ]; then
  SOURCE_DIR=`pwd`
fi

case $CORE_ARCH in
  amd64)
    OTHER_ARCH=x86_64
    ;;
  *)
    OTHER_ARCH=i386
    ;;
esac

mkdir -p debs

CHEF_URL=https://opscode-omnibus-packages.s3.amazonaws.com/ubuntu/$CORE_VERSION/$OTHER_ARCH/chef_11.6.0-1.ubuntu.13.04_$CORE_ARCH.deb
CHEF_FILE=$(basename $CHEF_URL)

if [ $(id -u) != '0' ]; then
  exec sudo $0 $@
fi

export LC_ALL=C

MAKESELF_URL=https://github.com/megastep/makeself/archive/master.tar.gz
MAKESELF_FILE=makeself.tar.gz
MAKESELF_DIR=makeself-master

[ -f $MAKESELF_FILE ] || wget -O${MAKESELF_FILE} $MAKESELF_URL
[ -d $MAKESELF_DIR ] || tar xf $MAKESELF_FILE

if ! which berks; then
  apt-get update
  apt-get -y install build-essential libxml2-dev libxslt-dev
  apt-get -y --no-install-recommends install ruby1.9.3 ruby1.9.1-dev
  gem install berkshelf
fi

# TODO should we use debootstrap for this?
# https://wiki.ubuntu.com/DebootstrapChroot
BUILD_DIR=$1
if [ -z $BUILD_DIR ]; then
  BUILD_DIR=$(mktemp -d /tmp/chef_container.XXXXXXXXXX)
else
  mkdir -p $BUILD_DIR
fi

echo "Build directory is: $BUILD_DIR"

if [ ! -d $BUILD_DIR/etc ]; then
  [ -f $CORE_TGZ ] || wget $CORE_URL
  tar -xf $CORE_TGZ -C $BUILD_DIR
fi

[ -f debs/$CHEF_FILE ] || wget -Odebs/$CHEF_FILE $CHEF_URL

cp /etc/resolv.conf $BUILD_DIR/etc/
cp debs/$CHEF_FILE $BUILD_DIR/tmp

if [ -d debs ]; then
  # This is so huge it just clears the scrollback
  # buffer
  set +x
  cp debs/*.deb $BUILD_DIR/var/cache/apt/archives/
  set -x
fi

(
  cd $SOURCE_DIR
  berks install -p ${BUILD_DIR}${CHEF_DIR}/vendored_cookbooks
)

mkdir -p ${BUILD_DIR}${CHEF_DIR}
for i in node.json chef_solo.rb data_bags roles cookbooks; do
  if [ -e $SOURCE_DIR/$i ]; then
    cp -a $SOURCE_DIR/$i ${BUILD_DIR}${CHEF_DIR}
  fi
done
  
mount -t proc proc $BUILD_DIR/proc
## Make super sure this gets unmounted
trap "umount $BUILD_DIR/proc" 0 1 2 3 13 15

set +e

chroot $BUILD_DIR /bin/bash -c "dpkg -i /tmp/$CHEF_FILE && /opt/chef/bin/chef-solo -c $CHEF_DIR/chef_solo.rb -l debug"
exit_code=$?

umount $BUILD_DIR/proc

set -e

# This is so huge it just clears the scrollback
# buffer
set +x
cp $BUILD_DIR/var/cache/apt/archives/*.deb ./debs/
set -x

if [ $exit_code == 0 ]; then
  chroot $BUILD_DIR apt-get clean

  cp $SOURCE_DIR/run.sh $BUILD_DIR/
  OPTS=--nox11

  if [ -f package.lsm ]; then
    OPTS="$OPTS --lsm package.lsm"
  fi

  rm -f package.bin
  $MAKESELF_DIR/makeself.sh $OPTS $BUILD_DIR package.bin "Container" chroot ./ env -i /run.sh

  cp package.bin $SOURCE_DIR/
fi

echo "Build directory is: $BUILD_DIR"
echo "Exit code of the inner shell was: $exit_code"
exit $exit_code

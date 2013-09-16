
#!/bin/sh

set -e
set -x

if [ $(id -u) != '0' ]; then
  exec sudo $0 $@
fi

BUILD_DIR=
CORE_ARCH=amd64
CORE_VERSION=13.04
CORE_URL=http://cdimage.ubuntu.com/ubuntu-core/releases/$CORE_VERSION/release/ubuntu-core-$CORE_VERSION-core-$CORE_ARCH.tar.gz
CORE_TGZ=$(basename $CORE_URL)

while getopts “p:” OPTION
do
  case $OPTION in
    p) BUILD_DIR=$OPTARG
  esac
done

shift $(($OPTIND - 1))

if [ -z $BUILD_DIR ]; then
  BUILD_DIR=$(mktemp -d /tmp/build.XXXXXXXXXX)
else
  mkdir -p $BUILD_DIR
fi

echo "Build directory is: $BUILD_DIR"
mkdir -p $BUILD_DIR/tmp/outputs

if [ ! -d $BUILD_DIR/etc ]; then
  [ -f $CORE_TGZ ] || wget $CORE_URL
  tar -xf $CORE_TGZ -C $BUILD_DIR
fi

cp /etc/resolv.conf $BUILD_DIR/etc/

if [ -d /tmp/debs ]; then
  # This is so huge it just clears the scrollback
  # buffer
  set +x
  cp /tmp/debs/*.deb $BUILD_DIR/var/cache/apt/archives/
  set -x
fi

mount -t proc proc $BUILD_DIR/proc
mount -r --bind ./ $BUILD_DIR/mnt

# Because this directory gets clobbered *way* too often
# when cleaning up old chroots
mount -o remount,ro,bind $BUILD_DIR/mnt

trap "umount $BUILD_DIR/proc; umount $BUILD_DIR/mnt" 0 1 2 3 13 15

set +e

chroot $BUILD_DIR bash -c "cd /mnt && env HOME=/home ./build.sh $@"
exit_code=$?

set -e

# This is so huge it just clears the scrollback
# buffer
set +x
mkdir -p /tmp/debs
cp $BUILD_DIR/var/cache/apt/archives/*.deb /tmp/debs/

cp -r $BUILD_DIR/tmp/outputs ./
set -x

echo "Build directory is: $BUILD_DIR"
echo "Exit code of the inner shell was: $exit_code"

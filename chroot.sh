
#!/bin/sh

set -e
set -x

if [ $(id -u) != '0' ]; then
  exec sudo $0 $@
fi

SOURCE_DIR=`pwd`
BUILD_DIR=
SKIP_PACKAGE=
CORE_ARCH=amd64
CORE_VERSION=13.04
CORE_URL=http://cdimage.ubuntu.com/ubuntu-core/releases/$CORE_VERSION/release/ubuntu-core-$CORE_VERSION-core-$CORE_ARCH.tar.gz
CORE_TGZ=$(basename $CORE_URL)

while getopts “sp:” OPTION
do
  case $OPTION in
    p) BUILD_DIR=$OPTARG
      ;;
    s) SKIP_PACKAGE=1
  esac
done

shift $(($OPTIND - 1))

if [ -z $BUILD_DIR ]; then
  BUILD_DIR=$(mktemp -d /tmp/build.XXXXXXXXXX)
else
  mkdir -p $BUILD_DIR
fi

echo "Build directory is: $BUILD_DIR"

if [ ! -d $BUILD_DIR/etc ]; then
  [ -f $CORE_TGZ ] || wget $CORE_URL
  tar -xf $CORE_TGZ -C $BUILD_DIR
fi

cp /etc/resolv.conf $BUILD_DIR/etc/
cp /etc/apt/apt.conf.d/01proxy $BUILD_DIR/etc/apt/apt.conf.d/

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

mkdir -p /tmp/debs

# This is so huge it just clears the scrollback
# buffer
set +x
if ls $BUILD_DIR/var/cache/apt/archives/*.deb > /dev/null; then
  cp $BUILD_DIR/var/cache/apt/archives/*.deb /tmp/debs/
fi
set -x

umount $BUILD_DIR/proc
umount $BUILD_DIR/mnt

if [ -z $SKIP_PACKAGE ] && [ $exit_code -eq 0 ]; then
  rm $BUILD_DIR/etc/apt/apt.conf.d/01proxy
  rm $BUILD_DIR/etc/resolv.conf

  (
    cd $BUILD_DIR
    $SOURCE_DIR/makeself/makeself.sh --nox11 ./ $SOURCE_DIR/package.bin "Container" $(cat command_line)
  )

  rm -r $BUILD_DIR
fi

set +x
echo "Build directory is: $BUILD_DIR"
echo "Exit code of the inner shell was: $exit_code"

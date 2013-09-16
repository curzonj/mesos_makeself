
Builds a tarball OS "container" using chef

The Berksfile contains your cookbooks and the node.json
tells chef how to run them.

    vagrant up

Then you'll have a package.bin file in your directory that is a
self-executable tarball that runs your run.sh in an ubuntu-core
chroot. This executable should run anywhere, including off a
[busybox ramdisk](https://github.com/curzonj/buildroot_vagrant).

Makeself is easier to install and more featureful than
[arx](https://github.com/solidsnack/arx) but it's binaries cannot
be executed by piping them to sh. You have to save the script
and either run it or run `sh package.bin` because the script
inspects itself using $0. We may change to arx in the future.

If you want to pipe a script from curl to sh, you might just write
a "wrapper" script and put it at a different url next to the
package.bin file. eg.

    #/bin/sh

    wget -Opackage.bin FULL_URL
    sh FULL_URL

## Without vagrant

You can also just run ./build.sh on any linux system and get the
same result.

## Debugging

If the build fails in the middle of chef you can just run the following
after you find the BUILD_DIR.
   
    sudo mount -t proc proc $BUILD_DIR/proc
    sudo chroot $BUILD_DIR /opt/chef/bin/chef-solo -c /tmp/chef/chef_solo.rb
    

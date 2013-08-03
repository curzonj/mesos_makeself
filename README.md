
Builds a tarball OS "container" using chef

The Berksfile contains your cookbooks and the node.json
tells chef how to run them.

    vagrant up

Then you'll have a package.bin file in your directory that is a
self-executable tarball that runs your run.sh in an ubuntu-core
chroot. This executable should run anywhere, including off a
[busybox ramdisk](https://github.com/curzonj/buildroot_vagrant).



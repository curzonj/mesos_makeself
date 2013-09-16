#!/bin/bash

set -e
set -x

mount -t proc proc /proc

echo "Hello World"
pwd

#!/bin/sh

export CFLAGS="-O3 -pipe -march=x86-64-v2 -mtune=generic -fno-math-errno -fstack-protector-strong --param ssp-buffer-size=4 -D_FORTIFY_SOURCE=2"
export CXXFLAGS="$CFLAGS"
export MAKEFLAGS="-j2"

export CMAKE_GENERATOR=Ninja
export LANG=en_US.UTF-8

export KISS_PATH=
export KISS_TMPDIR=/tmp
export KISS_COMPRESS=xz

KISS_PATH="$KISS_PATH:$HOME/kiss/repo/core"
KISS_PATH="$KISS_PATH:$HOME/kiss/repo/extra"
KISS_PATH="$KISS_PATH:$HOME/kiss/community/community"
KISS_PATH="$KISS_PATH:$HOME/kiss/kiss-repo/repo"

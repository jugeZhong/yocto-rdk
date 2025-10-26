#!/bin/bash

SCRIPT_DIR=$(pwd)

rm -rf $SCRIPT_DIR/build
mkdir -p $SCRIPT_DIR/build
mkdir -p $SCRIPT_DIR/out
cp $SCRIPT_DIR/templates/* build/ -rf
cd $SCRIPT_DIR/poky
git checkout -b f16cffd030d21d12dd57bb95cfc310bda41f8a1f
cd $SCRIPT_DIR/meta-openembedded
git checkout -b e621da947048842109db1b4fd3917a02e0501aa2

cd $SCRIPT_DIR
source poky/oe-init-build-env




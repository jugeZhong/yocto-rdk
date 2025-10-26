#!/bin/bash

SCRIPT_DIR=$(pwd)

rm -rf $SCRIPT_DIR/build
mkdir -p $SCRIPT_DIR/build
mkdir -p $SCRIPT_DIR/out
cp $SCRIPT_DIR/templates/* build/ -rf

cd $SCRIPT_DIR/poky
./oe-init-build-env




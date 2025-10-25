#!/bin/bash


rm -rf build
mkdir -p build
cp templates/* build/ -rf

source poky/oe-init-build-env




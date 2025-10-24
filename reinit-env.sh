#!/bin/bash

SCRIPT_DIR=$(pwd)

# 移除已存在的build目录
rm -rf build


# 初始化poky构建环境
source poky/oe-init-build-env

# 复制templates目录下的所有内容到build目录
cp $SCRIPT_DIR/templates/downloads $SCRIPT_DIR/build/ -rf
cp $SCRIPT_DIR/templates/conf/* $SCRIPT_DIR/build/conf -rf

#!/bin/sh

dir=$(cd `dirname $0`; pwd)

if [ ! $1 ]; then
    cmd='all'
else
    cmd=$1
fi

echo $dir
echo $1

if [ $cmd = "all" ]; then
    git submodule update --init

    echo -e "\nmake skynet"
    cd $dir/skynet && pwd
    make linux

    echo -e "\nmake pbc"
    cd $dir/lualib-src/pbc && pwd
    make lib
    #make && make -C binding/lua53/ TARGET=$dir/luaclib/protobuf.so

    echo -e "\nmake luaclib"
    cd $dir/lualib-src && pwd
    make linux

    echo -e "\nmake proto"
    cd $dir && pwd
    make
elif [ $cmd = "clean" ];then
    echo -e "\nclean skynet"
    cd $dir/skynet && pwd
    make clean

    echo -e "\nclean luaclib"
    cd $dir/lualib-src && pwd
    make clean
else
    echo "make help"
    echo "make.sh all"
    echo "make.sh clean"
fi

#!/bin/sh

for pid in ./pids/*.pid;
do
    kill -9 `cat $pid`
done

#!/bin/bash
# Commands needed to turn a vanilla EC2 Amazon Linux 2 machine into
# one that's ready to build & use udt, udt4py, and aws commands.
sudo yum install python37
sudo yum install gcc
sudo yum install gcc-c++
sudo yum install git
sudo yum install python3-devel


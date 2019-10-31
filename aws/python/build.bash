#!/bin/bash
# Build udt4py. This script can only be run from the .../aws/python directory and must
# be executed either on an EC2 Amazon Linux2 instance or in a Docker container emulating
# the Lambda environment in order for it to be runtime binary compatible with Lambda execution.
# Make sure the the ec2-prep command has been run before attempting this from EC2!
# 
# To prepare to run this script, see ../ec2-prep.bash
# To package the result of running this script, see ./package.py
# To clean up the artifacts from this script, see ./clean.bash

# Ensure that udt4 itself has been built
pushd ../../udt/udt4
make
popd

# Create a Python virtual environment
rm -rf venv
mkdir venv
python3 -m venv venv
. venv/bin/activate

# Ensure websockets installed; we'll add this to the layer
pip install websockets
pip install boto3

# Cython build requires the C/C++ udt4 includes in order to compile
export LD_LIBRARY_PATH=../../udt/udt4/src
python setup.py build_ext --inplace

# Minimal test to ensure build, install, and LD_LIBRARY_PATH all work
echo "from udt4py import UDTSocket; socket = UDTSocket()" | python

# Stage for publishing but don't actually publish in this script
rm -rf stage_layer
export DIR=stage_layer/python/lib/python3.7/site-packages
mkdir stage_layer && mkdir stage_layer/lib && mkdir stage_layer/python && mkdir stage_layer/python/lib && mkdir stage_layer/python/lib/python3.7 && mkdir $DIR
# Package UDT C++ networking library
cp ../../udt/udt4/src/libudt.so stage_layer/lib
# Package udt4py Python wrapper
cp udt4py.cpython-37m-x86_64-linux-gnu.so $DIR
# Package the required Python dependencies (websockets, e.g.)
# Remove C files and all pyc's in the __pycache__; they're not needed for layer execution.
cp -r venv/lib/python3.7/site-packages/websockets $DIR
rm -rf $DIR/websockets/__pycache__
rm -f $DIR/websockets/*.c
rm -rf $DIR/websockets/extensions/__pycache__
cd stage_layer && zip -r layer.zip lib python

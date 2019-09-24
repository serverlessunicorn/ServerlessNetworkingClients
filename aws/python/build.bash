#!/bin/bash
# Build udt4py. This script can only be run from the .../aws/python directory.
# Make sure the the ec2-prep command has been run before attempting this!

# Ensure that udt4 itself has been built
pushd ../../udt/udt4
make
popd

# Create a Python virtual environment to build and run tests
mkdir venv
python3 -m venv venv
. venv/bin/activate

# Cython build requires the C/C++ udt4 includes in order to compile
python setup.py build_ext --inplace

# Minimal test to ensure build, install, and LD_LIBRARY_PATH all work
export LD_LIBARY_PATH=”../../udt/udt4”
echo "from udt4py import UDTSocket; socket = UDTSocket()" | python


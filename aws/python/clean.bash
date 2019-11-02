#!/bin/bash
# Clean the pyx build artifacts
python setup.py clean --all
rm -rf *egg*
rm -f *.so
rm -f src/*.cpp
rm -rf stage_layer
rm -rf build
pushd python_packages
python setup.py clean --all
rm -rf *.egg-info
rm -rf dist
rm -rf __pycache__
rm -rf lambda_networking/__pycache__
popd


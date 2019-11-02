#!/bin/bash
# Clean the pyx build artifacts
python setup.py clean --all
rm -rf *egg*
rm -f *.so
rm -f lambda_networking/*.cpp
rm -rf stage_layer
rm -rf build

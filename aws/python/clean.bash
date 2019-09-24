#!/bin/bash
# Clean the pyx build artifacts
python setup.py clean --all
rm -rf *egg*
rm -f *.so
rm -f src/*.cpp
rm -rf stage_layer

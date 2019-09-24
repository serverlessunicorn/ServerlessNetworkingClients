#!/bin/bash
# Publish a staged layer to AWS Lambda
# TODO: Offer versioning versus replacement as an argument to this script
aws lambda publish-layer --zipfile b"stage_layer/layer.zip" --version 1
aws lambda add-layer-perm stuff

#!/bin/bash

# Publish a built & deployed test/example file to the Serverless Application Repository ("SAR)
# You must execute ./build.bash before this command can be run.
echo "sam publish invoked..."
sam publish --template output.yaml --region us-east-1
echo "...sam publish step complete"

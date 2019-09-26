#!/bin/bash

# Settings
export GEN_TEMPLATE=output.yaml
export S3_BUCKET=timsuseast1s3testbucket
export STACK_NAME=pythontests

# Build steps
# Note that requirements.txt is empty; all requirements needed for this code
# to run should come either from the Lambda python environment or the serverless networking
# client layer; users should never have to install additional Python packages to use it.
# (In the future, any *optional* packages should be tested separately to keep this assertion test
# cleanly validated here.)
touch src/requirements.txt
echo "Building..."
sam build
echo "Packaging..."
sam package --output-template $GEN_TEMPLATE --s3-bucket $S3_BUCKET
echo "Deploying..."
sam deploy --template-file $GEN_TEMPLATE --stack-name $STACK_NAME --capabilities CAPABILITY_NAMED_IAM
echo "...SAM cloud deployment is complete; see $STACK_NAME on CloudFormation console to manage"

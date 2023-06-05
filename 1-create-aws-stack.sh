#!/bin/bash

aws cloudformation deploy \
  --template-file create-aws-stack.json \
  --stack-name "create-aws-stack" \
  --output json \
  --parameter-overrides file://./secret.json

echo "Successfully created AWS stack."
echo "Please check https://quicksight.aws.amazon.com/sn/console/vpc-connections to ensure the 'Status' of VPC Connection is AVAILABLE."
echo "If the 'Status' is UNAVAILABLE, please wait for a while and check again."

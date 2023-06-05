#!/bin/bash

aws cloudformation deploy \
  --template-file create-aws-stack.json \
  --stack-name "create-aws-stack" \
  --output json \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides file://./secret.json

#!/bin/bash

aws cloudformation deploy \
  --template-file create-quicksight-stack.json \
  --stack-name "create-quicksight-stack" \
  --output json \
  --parameter-overrides file://./secret.json

echo "Successfully created Amazon QuickSight stack."
echo "Feel free to explore the TiDB Database via Amazon QuickSight https://quicksight.aws.amazon.com/sn/start/analyses"

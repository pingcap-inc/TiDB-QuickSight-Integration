#!/bin/bash

aws cloudformation delete-stack --stack-name "create-quicksight-stack"
aws cloudformation delete-stack --stack-name "create-aws-stack"

echo "Successfully deleted deploied resources."
echo "VPC connection recycles maybe delayed, please check https://quicksight.aws.amazon.com/sn/console/vpc-connections."
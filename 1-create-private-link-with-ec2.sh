STACK_NAME="private-link-with-ec2"

aws cloudformation deploy \
  --template-file 1-private-link-with-ec2.json \
  --stack-name ${STACK_NAME} \
  --output json \
  --parameter-overrides file://./1-secret.json

echo "\nIf success, this is the VPC Endpoint ID, please paste it to the TiDB Cloud:\n"

aws cloudformation describe-stacks \
  --stack-name ${STACK_NAME} \
  --query "Stacks[0].Outputs[?OutputKey=='QuickSightVPCEndpointID'].OutputValue|join(', ', @)" \
  > vpc-endpoint.id

cat vpc-endpoint.id

echo ""

echo "Those are the properties for create Amazon QuickSight:"
echo "Link: https://quicksight.aws.amazon.com/sn/console/vpc-connections/new"

security_group_id=`aws cloudformation describe-stacks \
  --stack-name ${STACK_NAME} \
  --query "Stacks[0].Outputs[?OutputKey=='QuickSightSecurityGroupID'].OutputValue|join(', ', @)"`

resolver_endpoint_id=`aws cloudformation describe-stacks \
  --stack-name ${STACK_NAME} \
  --query "Stacks[0].Outputs[?OutputKey=='QuickSightResolverEndpointID'].OutputValue|join(', ', @)"`

echo "\nQuickSightSecurityGroupID: ${security_group_id}"
echo "QuickSightResolverEndpointID: ${resolver_endpoint_id}"
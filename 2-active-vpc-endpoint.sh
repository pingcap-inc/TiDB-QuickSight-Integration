VPC_ENDPOINT_ID=`cat vpc-endpoint.id|tr -d '"'`

aws ec2 modify-vpc-endpoint \
  --vpc-endpoint-id ${VPC_ENDPOINT_ID} \
  --private-dns-enabled
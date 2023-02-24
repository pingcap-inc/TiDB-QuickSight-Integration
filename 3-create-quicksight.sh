aws cloudformation deploy \
    --template-file 3-quicksight.json \
    --stack-name quicksight-stack \
    --parameter-overrides file://./3-secret.json
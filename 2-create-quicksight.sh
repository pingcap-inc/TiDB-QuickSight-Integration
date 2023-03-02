aws cloudformation deploy \
    --template-file 2-quicksight.json \
    --stack-name quicksight-stack \
    --parameter-overrides file://./2-secret.json
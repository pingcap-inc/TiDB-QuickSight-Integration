# Amazon QuickSight Connect to TiDB Cloud via AWS PrivateLink

This document will show you how to integrate the [TiDB Cloud](https://tidbcloud.com/) Serverless Tier Cluster and [Amazon QuickSight](https://aws.amazon.com/quicksight/) via [AWS PrivateLink](https://aws.amazon.com/privatelink/). In this document, we need to use [AWS CloudFormation](https://aws.amazon.com/cloudformation/) and [AWS CLI](https://aws.amazon.com/cli/) to simplify progress.

## Overview

> **Note:**
>
> This is a simple overview. It only has the highest hierarchy component.

![simple overview](/assets/simple-overview.png)

The outline progress is:

1. `[Terminal]` Run the first script `1-create-private-link-with-ec2.sh`. Create the VPC (with the surrounding components), EC2 Interface, VPC Endpoint, etc.
2. `[Console]` Use the **VPC Endpoint ID** from the first step to confirm in TiDB Cloud.
3. `[Console]` Use the **Security Group ID** and **Resolver Endpoint ID** to create the VPC connection ARN.
4. `[Terminal]` Run the second script `2-active-vpc-endpoint.sh` to activate the **VPC Endpoint**.
5. `[Terminal]` Run the third script `3-create-quicksight.sh` to create the **QuickSight** components.
6. `[QuickSight]` Start analysis on Amazon QuickSight.
7. `[Terminal]` (Optional) Run the `4-clean.sh` script to clean the environment.

## Prerequisites

Before you can use this project, you will need the following:

- [Git](https://git-scm.com/)
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) version 2
- A [TiDB Cloud](https://tidbcloud.com/) Account
- An AWS [Identity and Access Management (IAM) user](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users.html) with the following requirements:

  - The user can access AWS using an [access key](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html).
  - The user has the following permissions:

    - `AWSCloudFormationFullAccess`: This guide uses the **AWS CloudFormation** to create AWS resources.
    - `AmazonEC2FullAccess`: To create the **VPC**, **Subnet**, **VPCEndpoint**, **InternetGateway**, **Route**, **RouteTable**, **SecurityGroup**, **EC2Instance**, etc.
    - `AmazonRoute53ResolverFullAccess`: To create **Route53Resolver**.
    - The **Amazon QuickSight** doesn't have an AWS managed policy. So you need to [create a customer inline policy](https://uconsole.aws.amazon.com/iam/home#/policies$new?step=edit), and add this permission to this user:

      ```json
      {
        "Version": "2012-10-17",
        "Statement": [
          {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "quicksight:*",
            "Resource": "*"
          }
        ]
      }
      ```

- An Amazon QuickSight Account of Enterprise Edition. The VPC feature is [for Enterprise Edition only](https://docs.aws.amazon.com/quicksight/latest/user/working-with-aws-vpc.html).

## Before you begin

> **Note:**
>
> Keep the same AWS region to your **TiDB Cloud Serverless Tier Cluster**, **Amazon QuickSight**, and your **AWS CLI default region**.

- Create a [TiDB Cloud](https://tidbcloud.com/) account and get your free trial cluster(Serverless Tier).
- Create a [TiDB Cloud Private Endpoint](https://docs.pingcap.com/tidbcloud/set-up-private-endpoint-connections), and get the **Endpoint ServiceName**.
- (Optional) If you never use the **AWS CLI** before, config it by:

  ```bash
  aws configure
  ```

- Import a dataset for analysis. In this document, use Fitness Trackers Products E-commerce for example. You can use [fitness_trackers.sql](/data/fitness_trackers.sql) to create the table in TiDB.

## 1. Create the VPC (With all components) / PrivateLink / EC2

![Step 1](/assets/1-private-link-with-ec2-designer.png)

1. Rename the `1-secret.template.json` to `1-secret.json`.
2. Replace the `ParameterValue` of `TiDBVPCEndpointServiceName` with your TiDB Cloud vpc endpoint service name.
3. Run the script: `1-create-private-link-with-ec2.sh`.

  ```bash
  ./1-create-private-link-with-ec2.sh
  ```

4. The end of the output message will look like the one below. Please remember the `VPC Endpoint ID`, `QuickSightSecurityGroupID`, and `QuickSightResolverEndpointID` to use in the next two steps:

  ```bash
  If successful, this is the VPC Endpoint ID, please paste it to the TiDB Cloud:

  "vpce-002271faf39889e3d"

  Those are the properties for creating Amazon QuickSight:
  Link: https://quicksight.aws.amazon.com/sn/console/vpc-connections/new

  QuickSightSecurityGroupID: "sg-0f840ba1620e0358d"
  QuickSightResolverEndpointID: "10.2.1.254,10.2.1.255"
  ```

> **Note:**
>
> If you want to know the actual effect of each resource, please click the component links to get more information:
>
> - [AWS::EC2::VPC](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-vpc.html)
> - [AWS::EC2::Subnet](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-subnet.html)
> - [AWS::EC2::RouteTable](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-routetable.html)
> - [AWS::EC2::Route](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-route.html)
> - [AWS::EC2::SubnetRouteTableAssociation](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-subnetroutetableassociation.html)
> - [AWS::EC2::SecurityGroup](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-security-group.html)
> - [AWS::Route53Resolver::ResolverEndpoint](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-route53resolver-resolverendpoint.html)
> - [AWS::EC2::VPCEndpoint](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-vpcendpoint.html)
> - [AWS::EC2::Instance](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-instance.html)
> - [AWS::EC2::InternetGateway](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-internetgateway.html)
> - [AWS::EC2::VPCGatewayAttachment](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-vpc-gateway-attachment.html)

## 2. Confirm VPC Endpoint ID in TiDB Cloud

> [WIP] TiDB Serverless Tier Cluster VPC PrivateLink not prepared. Use Dedicated Tier instead.

Use the output param `VPC Endpoint ID` from the [first step](#1-create-the-vpc-with-all-components--privatelink--ec2) to confirm in the TiDB Cloud.

## 3. Create the VPC Connection ARN

- Go to the page to [create a VPC Connection](https://quicksight.aws.amazon.com/sn/admin#vpc-connections).
- Click **VPC connection**.
- Select VPC named `quick-sight-vpc` and the only subnet.
- Fill in the `QuickSightSecurityGroupID`(from the [first step](#1-create-the-vpc-with-all-components--privatelink--ec2)) to `Security group ID`.
- Fill in the `QuickSightResolverEndpointID` (from the [first step](#1-create-the-vpc-with-all-components--privatelink--ec2))to `DNS resolver endpoints (optional)`.

  ![quicksight-vpc-connection](/assets/quicksight-vpc-connection.png)

- Click `Create`.
- Remember the `VPC connection ARN` param to use later.

  ![quicksight-vpc-connection-arn](/assets/quicksight-vpc-connection-arn.png)

## 4. Active the VPC Endpoint

You can activate the VPC Endpoint after the TiDB Cloud is confirmed.

```bash
./2-active-vpc-endpoint.sh
```

## 5. Create QuickSight Dataset

This step will create an Amazon QuickSight datasource via VPC connection to TiDB. And use this datasource to create a dataset which is the table `fitness_trackers` we imported.

![Step 5](/assets/3-quicksight-designer.png)

> **Note:**
>
> If you don't know how to get the params, you can read those documents to get more information:
>
> - [TiDB Cloud - Connect via Private Endpoint](https://docs.pingcap.com/tidbcloud/set-up-private-endpoint-connections#connect-via-private-endpoint)
> - [TiDB](https://docs.pingcap.com/tidb/stable)
> - [Amazon QuickSight](https://docs.aws.amazon.com/quicksight/latest/user/welcome.html)

1. Rename the `3-secret.template.json` to `3-secret.json`.
2. Replace those params:

  - `QuickSightVPCConnectionArn`: The Arn you get in the [third step](#3-create-the-vpc-connection-arn).
  - `QuickSightUser`: The username of QuickSight.

    ![quicksight-username](/assets/quicksight-username.png)
    ![quicksight-username-detail](/assets/quicksight-username-detail.png)

  - `TiDBUser`: TiDB username
  - `TiDBPassword`: TiDB password
  - `TiDBDatabase`: TiDB database
  - `TiDBHost`: TiDB PrivateLink host
  - `TiDBPort`: TiDB port

3. Run the script: `3-create-quicksight.sh`.

  ```bash
  ./3-create-quicksight.sh
  ```

## 6. Start analysis on Amazon QuickSight

![quicksight-analysis](/assets/quicksight-analysis.png)

## 7. (Optional) Clean

- Delete the [VPC Connection](https://quicksight.aws.amazon.com/sn/admin#vpc-connections) in Amazon QuickSight.
- Run the clean script:

  ```bash
  ./4-clean.sh
  ```

## Noteworthy Things

- If anything goes wrong in AWS CloudFormation. You can see the [page of CloudFormation Stack](https://console.aws.amazon.com/cloudformation/home) to get more information.

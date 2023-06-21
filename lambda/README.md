# Amazon QuickSight Connect to TiDB Cloud with AWS Lambda

This document will show you how to integrate the [TiDB Cloud](https://tidbcloud.com/) Serverless Tier Cluster and [Amazon QuickSight](https://aws.amazon.com/quicksight/) via [AWS PrivateLink](https://aws.amazon.com/privatelink/). In this document, we need to use [AWS CloudFormation](https://aws.amazon.com/cloudformation/) and [AWS CLI](https://aws.amazon.com/cli/) to simplify progress.

## Overview

> **Note:**
>
> This is a simple overview. It only has the highest hierarchy component.

![simple overview](/assets/simple-overview.png)

The outline progress is:

1. Run the first script `1-create-aws-stack.sh`. Create the VPC (with the surrounding components), EC2 Interface, VPC Endpoint, etc.
2. Run the secound script `2-create-quicksight-stack.sh` to create the **QuickSight** components.
3. Start analysis on Amazon QuickSight.
4. Request lambda endpoint to update data, and observe the change in Amazon QuickSight.
5. (Optional) Run the `3-clean.sh` script to clean the environment.

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
- (Optional) If you never use the **AWS CLI** before, config it by:

  ```bash
  aws configure
  ```

- Import a dataset for analysis. In this document, use Fitness Trackers Products E-commerce for example. You can use [fitness_trackers.sql](/data/fitness_trackers.sql) to create the table in TiDB.

## Get Your Private Endpoint Information

[TiDB Cloud Private Endpoint](https://docs.pingcap.com/tidbcloud/set-up-private-endpoint-connections) will be created in Serverless Tier cluster automatically. So you can get the **Endpoint ServiceName** and **Availability Zone(AZ)** to input to the `secret.json`.

> **Note:**
>
> TiDB Cloud Serverless Tier will offer to you the **AZ** format like `usw2-az1`. This is the ID of AZ. And the name of **AZ** will [different between all of users](https://docs.aws.amazon.com/ram/latest/userguide/working-with-az-ids.html).
>
> ![az mapping](/assets/availability-zone-mapping.png)
>
> So you can use the `aws ec2 describe-availability-zones --region <region name>` to get information of AZs. The output will like:
>
> ```bash
> {
>    "AvailabilityZones": [
>        {
>            "State": "available",
>            "OptInStatus": "opt-in-not-required",
>            "Messages": [],
>            "RegionName": "us-west-2",
>            "ZoneName": "us-west-2a",
>            "ZoneId": "usw2-az2",
>            "GroupName": "us-west-2",
>            "NetworkBorderGroup": "us-west-2",
>            "ZoneType": "availability-zone"
>        }
>        ...
>      ]
>  }
> ```
>
> And then, you can get the correspodent relations of zone ID and zone name.

## 1. Fill Parameters

> **Note:**
>
> If you don't know how to get the params, you can read those documents to get more information:
>
> - [TiDB Cloud - Connect via Private Endpoint](https://docs.pingcap.com/tidbcloud/set-up-private-endpoint-connections#connect-via-private-endpoint)
> - [TiDB](https://docs.pingcap.com/tidb/stable)
> - [Amazon QuickSight](https://docs.aws.amazon.com/quicksight/latest/user/welcome.html)

1. Rename the `secret.template.json` to `secret.json`.
2. Replace those parameters:

  - `TiDBVPCEndpointServiceName`: TiDB Cloud VPC endpoint service name.
  - `TiDBServerlessAvailabilityZone`: The Availability Zone(AZ) of TiDB Serverless Tier Cluster.
  - `AnotherAvailabilityZone`: This is a quirky way to work around the restriction of Amazon QuickSight VPC Connection. Please input an AZ that  is not the same as `TiDBServerlessAvailabilityZone`.
  - `QuickSightRoleArn`: The AWS role you want to create resources.
  - `QuickSightUser`: The username of QuickSight.

    ![quicksight-username](/assets/quicksight-username.png)
    ![quicksight-username-detail](/assets/quicksight-username-detail.png)

  - `TiDBUser`: TiDB username
  - `TiDBPassword`: TiDB password
  - `TiDBDatabase`: TiDB database
  - `TiDBHost`: TiDB PrivateLink host
  - `TiDBPort`: TiDB port

## 1. Create the VPC (With all components) / PrivateLink / EC2 / Amazon QuickSight VPC Connection / AWS Lambda

![Step 1](/assets/1-private-link-with-ec2-designer.png)

1. Run the script: `1-create-aws-stack.sh`.

  ```bash
  ./1-create-aws-stack.sh
  ```

2. Waiting for the `Status` of [Amazon QuickSight VPC Connection](https://quicksight.aws.amazon.com/sn/console/vpc-connections) is `AVAILABLE`.

  ![qs-vpc-connection](/assets/qs-vpc-connection.jpg)

## 2. Create QuickSight Dataset

This step will create an Amazon QuickSight datasource via VPC connection to TiDB. And use this datasource to create a bookstore dataset which is the table `book` we imported.

![Step 5](/assets/2-quicksight-designer.png)

3. Run the script: `2-create-quicksight-stack.sh`.

  ```bash
  ./2-create-quicksight-stack.sh
  ```

## 4. Start analysis on Amazon QuickSight

![quicksight-analysis](/assets/quicksight-analysis.png)

## 5. (Optional) Clean

- Run the clean script:

  ```bash
  ./3-clean.sh
  ```

- The Amazon QuickSight VPC Connection recycles maybe delayed.

## Noteworthy Things

- If anything goes wrong in AWS CloudFormation. You can see the [page of CloudFormation Stack](https://console.aws.amazon.com/cloudformation/home) to get more information.

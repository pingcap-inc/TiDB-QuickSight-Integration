# Amazon QuickSight Connect to TiDB Cloud via AWS PrivateLink

<div align="right" style="color: gray"> —— Pure Console UI Version </div>

This document will show you how to integrate the [TiDB Cloud](https://tidbcloud.com/) Serverless Tier Cluster and [Amazon QuickSight](https://aws.amazon.com/quicksight/) via [AWS PrivateLink](https://aws.amazon.com/privatelink/). In this document, we need to use [AWS Console](https://console.aws.amazon.com/console/home) and [TiDB Cloud Console](https://tidbcloud.com/) to create it step by step.

## Video

[It will add the video for TiDB Serverless Tier & Amazon QuickSight]

## Overview

> **Note:**
>
> This is a simple overview. It only has the highest hierarchy component.

![manually overview](/assets/manually/manually-overview.png)

The outline progress is:

1. Create a [TiDB Cloud](https://tidbcloud.com/) Serverless Tier cluster.
2. Create a dedicated **VPC** and related components to contain all of your network. You can use `VPC and more` to speed up your creation.
3. Create an **Endpoint** in this VPC to link to TiDB Serverless Tier's **Endpoint Server**.
4. (Amazon QuickSight Enterprise Edition account required) Create a **VPC Connection** on the Amazon QuickSight management page.
5. Explore the dataset through TiDB and Amazon QuickSight!

## Prerequisites

Before you can use this project, you will need the following:

- A [TiDB Cloud](https://tidbcloud.com/) Account
- An Amazon QuickSight Account of Enterprise Edition. The VPC feature is [for Enterprise Edition only](https://docs.aws.amazon.com/quicksight/latest/user/working-with-aws-vpc.html).

## Before you begin

> **Note:**
>
> Keep the same AWS region for your **TiDB Cloud Serverless Tier Cluster** and **Amazon QuickSight**.

- Create a [TiDB Cloud](https://tidbcloud.com/) account and get your free trial cluster (Serverless Tier).
- Import a dataset for analysis. In this document, we will use [TPC-DS](https://www.tpc.org/tpc_documents_current_versions/current_specifications5.asp) as an example.

## Get Your Private Endpoint Information

The [TiDB Cloud Private Endpoint](https://docs.pingcap.com/tidbcloud/set-up-private-endpoint-connections) will be automatically created in the Serverless Tier cluster. You can obtain the **Service Name**, **Availability Zone ID (AZ ID)**, and **Region ID**. Please record this information for later use. To learn more, you can read the [private endpoint document](https://docs.pingcap.com/tidbcloud/set-up-private-endpoint-connections#set-up-a-private-endpoint-with-aws) of TiDB Cloud.

![TiDB Private Endpoint Information](/assets/manually/tidb-private-endpoint-info.jpg)

> **Note:**
>
> TiDB Cloud Serverless Tier will offer you the **AZ ID** format like `usw2-az1`. That's because the name of the **AZ** will [differ between all users](https://docs.aws.amazon.com/ram/latest/userguide/working-with-az-ids.html).
>
> ![AZ mapping](/assets/availability-zone-mapping.png)
>
> So, you can enter the homepage of [AWS Resource Access Manager](https://console.aws.amazon.com/ram/home#Home:). Then, you can get the corresponding relations between your AZ names and AZ IDs.
> ![AZ ID and AZ name correspondence](/assets/manually/azid-azname-correspond.jpg)

## 1. Create the VPC (With majority components)

You can add the VPC and majority components in the `Create VPC` step, by selecting the `VPC and more` option in the `Resources to create` section. Here are the configurations that you need to change or fill in:

- `Resources to create`: Select `VPC and more`.
- `Name tag auto-generation`: Provide a meaningful name for your VPC.
- `Customize AZs`: Check if the AZ name of your TiDB Serverless Tier cluster is in those two `Customize AZs`.
- `Number of private subnets`: `0`.

Then, click on `Create VPC` and wait for the successful creation.

## 2. Create Security Group

Create a new [Security Group](https://console.aws.amazon.com/vpc/home#SecurityGroups:) in this VPC to use later in the **Route Resolver**. This Security Group should allow all inbound TPC traffic. Record the Security Group ID.

![Security Group inbound rule](/assets/manually/sg-inbound-rule.jpg)
## 3. Create Route 53 Resolver

Create a [Route 53 Resolver Inbound endpoint](https://console.aws.amazon.com/route53resolver/home#/inbound-endpoints) with the following configurations:

- `Endpoint name`: Provide a meaningful name for your Route 53 Resolver Inbound endpoint.
- `VPC in the Region: xx-xxxx-x (xxxxxx)`: Select the VPC that you just created. Make sure the region matches the region where you created the VPC.
- `Security group for this endpoint`: Select the Security Group that you just created.
- `Endpoint Type`: Select `IPv4`.
- `IP address #1/#2`: Choose the same Availability Zone where your TiDB Cloud Serverless Tier is located. Since you have only one subnet, select it.

Click on `Create inbound endpoint` and wait for the successful creation.

Next, click on the ID of your inbound endpoint and record the `IP addresses`.

![Inbound endpoint IP addresses](/assets/manually/inbound-ips.jpg)

## 4. Create Endpoint

Create a VPC [Endpoint](https://console.aws.amazon.com/vpc/home#Endpoints:) with the following configurations:

- `Name tag`: Provide a meaningful name for your VPC Endpoint.
- `Service category`: Select the `Other endpoint services` option.
- `Service name`: You can obtain this service name from the TiDB Cloud Console UI. Refer to the [Get Your Private Endpoint Information](#get-your-private-endpoint-information) section for instructions on how to obtain the service name.

    Click on `Verify service`. It should show `Service name verified`.

    ![Service name verification](/assets/manually/service-name-verify.jpg)

- `VPC`: Select the VPC that you just created.
- `Subnets`: Since there is only one AZ and subnet to choose from, select them.
- `Security groups`: **ONLY** select the Security Group that you just created.

Click on `Create endpoint` and wait for the successful creation.
## 5. Enable Private DNS for Endpoint

Click on the `Modify private DNS name` button.

![Enable Private DNS for Endpoint](/assets/manually/enable-private-dns-for-enpoint.jpg)

Check the `Enable for this endpoint` option and click `Save changes`.

## 6. Add VPC Connection in Amazon QuickSight

In the [Manage VPC connections](http://quicksight.aws.amazon.com/sn/console/vpc-connections?#) page, click on `ADD VPC CONNECTION` to create a VPC connection with the following configurations:

- `VPC connection name`: Provide a meaningful name for your VPC connection.
- `VPC ID`: Select the VPC ID that you just created.
- `Execution role`: Amazon QuickSight has already created two roles for you by default. If you believe that the permissions of those roles are not sufficient, you can go to the [IAM](https://console.aws.amazon.com/iamv2/home#/roles) page to grant them additional permissions.
- `Subnets (Select at least two)`: In each AZ, there is only one `Subnet ID` to choose from, so select it.
- `Security Group IDs`: **ONLY** select the Security Group that you just created.
- `DNS resolver endpoints (optional)`: Use the `IP addresses` from the `Route 53 Resolver` that you just created.

Click on `ADD`, and wait for the successful creation and availability.

## 7. Create a Dataset

In the [Create a DataSet](https://us-west-2.quicksight.aws.amazon.com/sn/data-sets/new) page, click on `MySQL`. This is because TiDB is highly compatible with the MySQL 5.7 protocol, and the common features and syntax of MySQL 5.7 can be used for TiDB. The ecosystem tools for MySQL 5.7 and the MySQL client can also be used for TiDB.

![MySQL Data Source](/assets/manually/qs-mysql-data-source.jpg)

Configure the following settings:

- `Data source name`: Provide a meaningful name for your data source.
- `Connection type`: Select the VPC Connection that you just created.
- `Database server`/`Port`/`Username`: You can find these details in the TiDB Cloud Console.

    ![TiDB Private Endpoint Base Info](/assets/manually/tidb-private-endpoint-base-info.jpg)

- `Database name`: Enter the name of your TPC-DS database in the TiDB Serverless Tier cluster. Alternatively, you can enter any database name you want to explore in your TiDB Serverless Tier cluster.
- `Password`: Enter the password you set in TiDB Cloud.
- `Enable SSL`: Uncheck the `Enable SSL` option.

Click on `Validate connection`. It should show `Validated`.

![Data source verification](/assets/manually/datasource-verify.jpg)

Click on `Create data source`.

## 8. Explore via Complex Query

Next, we can explore the data by clicking on `Use custom SQL`. Let's see how well TiDB Cloud Serverless Tier cluster performs.

Here's a good query to try:

```sql
SELECT dt.d_year, 
               item.i_brand_id          brand_id, 
               item.i_brand             brand, 
               Sum(ss_ext_discount_amt) sum_agg 
FROM   date_dim dt, 
       store_sales, 
       item 
WHERE  dt.d_date_sk = store_sales.ss_sold_date_sk 
       AND store_sales.ss_item_sk = item.i_item_sk 
       AND item.i_manufact_id = 427 
       AND dt.d_moy = 11 
GROUP  BY dt.d_year, 
          item.i_brand, 
          item.i_brand_id 
ORDER  BY dt.d_year, 
          sum_agg DESC, 
          brand_id
LIMIT 100;
```

Click on `Confirm query`, and then select `Directly query your data` followed by `Visualize`.

![dataset-creation-finished](/assets/manually/dataset-creation-finished.jpg)

## 9. Happy exploring

![QuickSight Explore](/assets/manually/qs-explore.jpg)

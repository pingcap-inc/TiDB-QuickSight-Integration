# Amazon QuickSight Connect to TiDB Cloud via AWS PrivateLink

<div align="right" style="color: gray"> —— Pure Console UI Version </div>

This document will show you how to integrate the [TiDB Cloud](https://tidbcloud.com/) Serverless Tier Cluster and [Amazon QuickSight](https://aws.amazon.com/quicksight/) via [AWS PrivateLink](https://aws.amazon.com/privatelink/). In this document, we need to use [AWS Console](https://console.aws.amazon.com/console/home) and [TiDB Cloud Console](https://tidbcloud.com/) to create it step by step.

## Solution Overview

Below is the architecture of a modern BI system using TiDB Cloud, Amazon QuickSight, and Amazon PrivateLink. Data is ingested into TiDB Cloud, prepared, stored, and analyzed in real-time, eliminating the need for ETL. QuickSight effortlessly transforms analysis into user-friendly dashboards, featuring charts and insights for informed decisions. Updates to TiDB Cloud data instantly reflect on QuickSight dashboards, ensuring access to the latest insights in a secure environment.

![manually overview](/assets/manually/image1.png)

Thanks to the HTAP architecture, TiDB Cloud provides real-time analytics directly on operational data. This is achieved through TiDB features like TiFlash, a real-time columnar storage engine that extends TiKV and uses asynchronous replication for real-time, consistent data without blocking transactional processing. The architecture is designed for scalability, with TiKV and TiFlash on separate storage nodes for complete isolation. TiDB's intelligent optimizer streamlines query execution by selecting the most efficient storage—either row or column—based on workload.

![HTAP Architecture of TiDB](/assets/manually/image12.png)

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

![add vpc connection](/assets/manually/image14.png)

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

In this section, we dive into the rich world of TPC-DS queries to examine how TiDB's TiKV and TiFlash components impact query execution times. We'll select a subset of complex analytical queries from the [TPC-DS repository](https://github.com/snithish/tpc-ds_big-query/tree/master/query), to showcase their execution with TiKV alone and then with TiFlash.

Before delving into query performance, we'll guide you through the process of adding TiFlash to the tables of interest. As we dissect each query, you'll witness firsthand the tangible differences in execution times, highlighting how TiFlash can significantly accelerate analytical tasks.

Here is an overview of the analytical queries we'll run on our dataset. At this stage, the TiDB query optimizer will employ the TiKV (OLTP) storage engine to parse, execute, and retrieve the results.

- Multi Year Sales by Category per Quarter

    This [query](https://github.com/snithish/tpc-ds_big-query/blob/master/query/query76.sql) provides a comprehensive overview of sales performance based on attributes like year, quarter, and product category. By leveraging this analysis, organizations can identify trends and opportunities to refine marketing, inventory management, and product offerings.

- Identifying Sales Anomalies for Effective Inventory Management

    This [query](https://github.com/snithish/tpc-ds_big-query/blob/master/query/query47.sql) delves into historical sales data to identify anomalies in product categories, brands, and stores. By analyzing sales figures from a particular year, it identifies instances where monthly sales significantly deviate from the average. These insights are invaluable for businesses in optimizing their inventory management strategies

- Store Sales by Day of Week

    This [query](https://github.com/snithish/tpc-ds_big-query/blob/master/query/query43.sql) analyzes store sales distribution across weekdays and weekends for various stores over a year, revealing customer shopping behavior trends. This data empowers stores to make informed decisions regarding staffing, promotions, and inventory management.

Click on `Confirm query`, and then select `Directly query your data` followed by `Visualize`.

![dataset-creation-finished](/assets/manually/dataset-creation-finished.jpg)

## 9. Optimizing Query Performance

Integrating a TiFlash replica set is a crucial step in optimizing query performance. In TiDB Serverless, achieving this is straightforward through simple DDL statements. These statements allow you to select the tables for which you want the smart query optimizer to deliver speedy results.

```sql
ALTER TABLE store_sales SET TIFLASH REPLICA 1;
ALTER TABLE item SET TIFLASH REPLICA 1;
ALTER TABLE date_dim SET TIFLASH REPLICA 1;
ALTER TABLE catalog_sales SET TIFLASH REPLICA 1;
ALTER TABLE web_sales SET TIFLASH REPLICA 1;
ALTER TABLE web_returns SET TIFLASH REPLICA 1;
ALTER TABLE catalog_returns SET TIFLASH REPLICA 1;
ALTER TABLE store_returns SET TIFLASH REPLICA 1;
ALTER TABLE warehouse SET TIFLASH REPLICA 1;
ALTER TABLE inventory SET TIFLASH REPLICA 1;
ALTER TABLE store SET TIFLASH REPLICA 1;
```

|Query|TiKV(ms)|TiKV + TiFlash(ms)|
|:-:|:-:|:-:|
|Multi Year Sales By Category Per Quarter|1729|1119|
|Identifying Sales Anomalies for Effective Inventory Management|4765|2322|
|Store Sales by Day of Week|4029|312|

## 10. Create an Analysis

Create an Analysis using the dataset we just created.

After you finish all the steps shown above, you can start to get visual charts, dashboards, and other visualized insights from Quicksight.

![QuickSight Explore](/assets/manually/image15.png)

## Summary

Integrating TiDB Cloud and Amazon Quicksight makes it easier for developers and companies to build a smarter, more efficient, and visualized BI system. Companies can process, store, and analyze their data in one place, which greatly simplifies the data architecture and reduces operation and maintenance costs. Companies can also get the most up-to-date visualized insights based on freshly generated business data. This helps them quickly make decisions and respond to changes.

If you’re interested in this integration, you are welcome to sign in to (or sign up for) your [TiDB Cloud](https://tidbcloud.com/signup) and [AWS QuickSight](https://aws.amazon.com/quicksight/) accounts and give them a try. If you have any questions, feel free to contact us through [Twitter](https://twitter.com/PingCAP), [LinkedIn](https://www.linkedin.com/company/pingcap/mycompany/), or our [Slack Channel](https://slack.tidb.io/invite?team=tidb-community&channel=everyone&ref=pingcap).

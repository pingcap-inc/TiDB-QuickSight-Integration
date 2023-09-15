# Integrate TiDB Cloud with AWS QuickSight

TiDB Cloud a fully-managed DBaaS offering of [TiDB](https://www.pingcap.com/tidb/), an advanced, open-source, distributed SQL database that features Hybrid Transactional and Analytical Processing (HTAP) capabilities. It enables businesses to process and analyze large amounts of data from the same source of truth reliably and cost-effectively, without using any ETL tools. [Amazon QuickSight](https://aws.amazon.com/quicksight/) is a cloud-based BI platform that allows businesses to create interactive dashboards, visualizations, and analyze data in real-time.

In this guide, we will guide you through how to integrate TiDB Cloud's Serverless offering with Amazon QuickSight via AWS Private Link. We will also demonstrate the potential of this pairing for a faster visual analysis utilizing the [TPC-DS](https://www.tpc.org/tpcds/default5.asp) dataset.

![stack](/assets/manually/image5.png)

## Prerequisites and Assumptions

Before getting started, please complete the following prerequisites:

- [Create a TiDB Cloud’s Serverless cluster](https://tidbcloud.com/signup), as we’ll be using TiDB Cloud to store TPC-DS dataset.
- [Create an AWS account](https://aws.amazon.com/), as we’ll be using various services such as Amazon  QuickSight, VPC Endpoint and Route53.
- [Create an Amazon QuickSight Enterprise Edition account](https://repost.aws/knowledge-center/quicksight-enterprise-account), only QuickSight Enterprise Edition fully integrates with Amazon VPC service.

## Step 1: Gather PrivateLink Info in TiDB Serverless

When you create your TiDB Serverless cluster, PrivateLink is automatically generated. You can follow the steps to get the information of the cluster.

1. Navigate to the [clusters page](https://tidbcloud.com/console/clusters/) within TiDB Cloud, and select the desired cluster by clicking on its name.
2. At the top-right corner of the page, click the “**Connect**” button.
3. In the connect window, choose “**Private**” from the “**Endpoint Type**” dropdown menu and select “**General**” under “**Connect With**”.
4. Take note of the Private Endpoint configuration values: **Service Name**, **Availability Zone ID**, and **Region ID**. Also, record the cluster connection parameters including **host**, **port**, **user**, and **password**.

![tidb connect panel](/assets/manually/image15.png)

## Step 2. Import tpc-ds dataset

Once you have the PrivateLink information, you can begin importing the TPC-DS dataset into TiDB Cloud for storage and analytics using the following steps,

1. [Download](https://tidb-immersion-day.s3.amazonaws.com/tpc-ds.zip) and extract the TPC-DS dataset folder, containing SQL files to create databases, tables, and insert sample data.
2. Sign in to your AWS Account, create a S3 bucket, and upload the TPC-DS SQL files.
3. Follow these [instructions](https://docs.pingcap.com/tidbcloud/import-csv-files#step-4-import-csv-files-to-tidb-cloud) to create the tables and import the dataset into TiDB Cloud.

## Step 3. Establish private connectivity between QuickSight and TiDB Serverless

Before proceeding to create the AWS QuickSight VPC Connection, you'll need to establish the VPC and its associated components to prepare your network appropriately.

### 1. Locate AZ Name

1. Log into your AWS Account, and choose the AWS region to be the same as the cluster's region.
2. Access [AWS Resource Access Manager](https://console.aws.amazon.com/ram/home?Home:) to find the AZ name for the [previously](#step-1-gather-privatelink-info-in-tidb-serverless) obtained Availability Zone ID, as it will be required in the subsequent action.

![AWS Resource Access Manager](/assets/manually/image13.png)

### 2. Create the VPC

1. In the VPC Service section, navigate to **Create VPC page > VPC settings > VPC and more**.
2. Provide a name tag for auto-generation (for example qs-tidb-serverless), and leave the default values for IPv4 CIDR block, IPv6 CIDR block.

    1. Configure the **Customize AZs** section as below:
    1. First availability zone: the one obtained earlier
    1. Second availability zone: default
    1. Number for private subnets: 0
    1. VPC endpoints: None
    1. Click “**Create VPC**”.

*Make a note of the VPC ID generated for future reference.*

![VPC](/assets/manually/image2.png)

### 3. Create a security group

1. Under the Network & Security section, navigate to EC2 > Security Groups > Create security group.
1. Configure the security group as shown below:

    - Enter a name for your security group (for example qs-tidb-serverless-sg) and a description.
    - For VPC, choose the VPC ID obtained in the previous step.
    - Add an inbound rule by choosing **Add rule** in the inbound rules. This will allow traffic from within your VPC to the VPC endpoint.
    - Choose Custom TCP for the type.
    - Enter 0 - 65535 for Port range.
    - Choose Anywhere-IPV4 as Source.

    ![security group](/assets/manually/image7.png)

1. Choose Create security group.

*Note down the security group ID.*

### 4. Configure a Route 53 resolver inbound endpoint for your VPC

1. On the Route 53 resolver console, choose **Inbound only** in the navigation pane, and configure the endpoint as described below:

    - Enter a name (for example, qs-tidb-serverless-resolver-endpoint) for the endpoint.
    - For VPC in the Region, choose the VPC ID obtained in previous steps.
    - For the security group for the endpoint, choose the Security group ID you saved earlier.
    - Choose IPv4 for Endpoint Type.
    - For IP address #1 & #2 choose the availability zones that you had chosen while creating the VPC.

    ![Route 53 resolver](/assets/manually/image11.png)

1. Click Next, review the details and click Submit,
1. Note down the IP addresses created at the end of the Route 53 Resolver Inbound endpoint creation process as we will be using them when connecting the VPC to QuickSight.

### 5. Create VPC Endpoints

1. In the **VPC Service** section, navigate to **Endpoints > Create endpoint**, and configure the end point as described below:
    - Choose **Other endpoint services** as the service category.
    - Enter the service name acquired in Step 1, which typically starts with “com.amazonaws.vpce”. Click **Verify service** to verify the service name.

        ![create endpoint](/assets/manually/image1.png)

    - Choose the **VPC ID** previously created.
    - **Enable DNS name** available under Additional settings.
    - Choose the **Availability Zone** and select the subnet that was created previously.
    - Choose the **Security group ID** previously created.

1. Click **Create Endpoint** and wait for a few minutes for the endpoint to be available.

    ![endpoint available](/assets/manually/image6.png)

### 6. Add a VPC Connection to QuickSight

1. Log into the Amazon QuickSight Enterprise edition, and navigate to **Manage QuickSight**. Note that you must be a QuickSight administrator to access this page.
1. In the left navigation pane, navigate to **Manage VPC connections > Add VPC connection**.
1. Configure the VPC connection as shown below, and click **ADD** to finish adding the VPC connection.

![vpc connection](/assets/manually/image12.png)

## Step 4 : Exploring TPC-DS dataset & performance

In this section, we dive into the rich world of TPC-DS queries to examine how TiDB's TiKV and TiFlash components impact query execution times. We'll select a subset of complex analytical queries from the [TPC-DS repository](https://github.com/snithish/tpc-ds_big-query/tree/master/query), typically about five queries, to showcase their execution with TiKV alone and then with TiFlash.

Before delving into query performance, we'll guide you through the process of adding TiFlash to the tables of interest. As we dissect each query, you'll witness firsthand the tangible differences in execution times, highlighting how TiFlash can significantly accelerate analytical tasks.

Here is an overview of the analytical queries we'll run on our dataset. At this stage, the TiDB query optimizer will employ the TiKV (OLTP) storage engine to parse, execute, and retrieve the results.

- Multi Year Sales by Category per Quarter

    This [query](https://github.com/snithish/tpc-ds_big-query/blob/master/query/query76.sql) provides a comprehensive overview of sales performance based on attributes like year, quarter, and product category. By leveraging this analysis, organizations can identify trends and opportunities to refine marketing, inventory management, and product offerings.

- Identifying Sales Anomalies for Effective Inventory Management

    This [query](https://github.com/snithish/tpc-ds_big-query/blob/master/query/query47.sql) delves into historical sales data to identify anomalies in product categories, brands, and stores. By analyzing sales figures from a particular year, it identifies instances where monthly sales significantly deviate from the average. These insights are invaluable for businesses in optimizing their inventory management strategies

- Store Sales by Day of Week

    This [query](https://github.com/snithish/tpc-ds_big-query/blob/master/query/query43.sql) analyzes store sales distribution across weekdays and weekends for various stores over a year, revealing customer shopping behavior trends. This data empowers stores to make informed decisions regarding staffing, promotions, and inventory management.

Integrating a TiFlash replica set is a crucial step in optimizing query performance. In TiDB Serverless, achieving this is straightforward through simple DDL statements. These statements allow you to select the tables for which you want the smart query optimizer to deliver speedy results.

### Add TiFlash Replica SQL

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

### TiFlash vs. TiKV

|Query|TiKV(ms)|TiKV + TiFlash(ms)|
|:-:|:-:|:-:|
|Multi Year Sales By Category Per Quarter|1729|1119|
|Identifying Sales Anomalies for Effective Inventory Management|4765|2322|
|Store Sales by Day of Week|4029|312|

As illustrated in the table above, enabling TiFlash resulted in a significant average performance gain of approximately 5 times (5x) across all the queries. Remarkably, this improvement remains consistent even during concurrent data ingestion.

## Step 5: Create QuickSight Dataset

In this section, we will establish a connection between QuickSight and TiDB Serverless using the information gathered from the previous steps. Once the connection is established, we will use the “[Store Sales by Day of Week query](https://github.com/snithish/tpc-ds_big-query/blob/master/query/query43.sql)” as an example to create a dataset. Please note that the steps for creating datasets for the other queries are similar and can be repeated as needed.

1. In the Amazon QuickSight portal, enter the **Create a Dataset** page and select **MySQL** as the data source.
1. Fill out all the connection information gathered from [Step 1](#step-1-gather-privatelink-info-in-tidb-serverless).

    Click **Validate** to test the connection. Then, click the **Create data source**.

    ![data source validate](/assets/manually/image14.png)

1. Click **Use custom SQL** to add the TPC-DS query.

    ![Use custom SQL](/assets/manually/image10.png)

1. In the pop-up box, add the “[Store Sales by Day of Week query](https://github.com/snithish/tpc-ds_big-query/blob/master/query/query43.sql)” and click **Confirm query**.
1. Click **Visualize** to create an Analysis using the dataset we just created.

    ![Visualize](/assets/manually/visualize.png)

After you finish all the steps shown above, you can start to get visual charts, dashboards, and other visualized insights from Quicksight. For example,

![result](/assets/manually/image4.png)

When using Amazon QuickSight, if you encounter any issues or seek additional information, please consult the [Amazon QuickSight documentation](https://docs.aws.amazon.com/quicksight/).
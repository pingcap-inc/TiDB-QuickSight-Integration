# Step by Step Guidance to Integrate AWS QuickSight and TiDB Cloud

## Create TiDB Cloud Cluster

[TiDB](https://github.com/pingcap/tidb) (/’taɪdiːbi:/, "Ti" stands for Titanium) is an open-source NewSQL database that supports Hybrid Transactional and Analytical Processing (HTAP) workloads. It is MySQL-compatible and features horizontal scalability, strong consistency, and high availability.

If you don't have a TiDB Cloud Dedicated Tier cluster yet, you can follow the document [Create a TiDB Cluster](https://docs.pingcap.com/tidbcloud/create-tidb-cluster) to create your cluster.

1. Log in to the platform of TiDB Cloud, and click “Create Cluster”.

    ![create cluster](/assets/create-cluster.png)

2. Click “Dedicated Tier” and fill up all the cluster fields. Suggest to choose AWS as the provider and the same region as AWS QuickSight. For example, we choose the **Oregon us-west-2** as the region.

    ![dedicated tier](/assets/dedicated-tier.png)

3. Choose the cluster size that you want and create it.
4. Wait a little while until the cluster is available.

    ![creating cluster](/assets/creating-cluster.png)
    ![created cluster](/assets/created-cluster.png)

5. Import a dataset from the Fitness Trackers Products Ecommerce for example. This dataset is related to fitness trackers. In this example, you need to use the **Fitness_trackers.csv** file.

    ![kaggle](/assets/kaggle.png)

6. Change the “Security Settings”

    ![security settings entrance](/assets/security-settings-entrance.png)
    ![security settings](/assets/security-settings.png)

7. Connect the connection information from the cluster. Suggest to use a GUI tool to connect. Then you can import a CSV file.

    ![connect](/assets/connect.png)

8. The DDL of new table is:

    ```sql
    CREATE TABLE `fitness_trackers` (
    `brand_name` varchar(255) DEFAULT NULL,
    `device_type` varchar(255) DEFAULT NULL,
    `model_name` varchar(255) DEFAULT NULL,
    `color` varchar(255) DEFAULT NULL,
    `selling_price` varchar(255) DEFAULT NULL,
    `original_price` varchar(255) DEFAULT NULL,
    `display` varchar(255) DEFAULT NULL,
    `rating` double DEFAULT NULL,
    `strap_material` varchar(255) DEFAULT NULL,
    `average_battery_life` int(11) DEFAULT NULL,
    `reviews` varchar(255) DEFAULT NULL
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
    ```

You can browse the PingCAP Documentation Home to get more fun information.

## Integrate AWS QuickSight and TiDB

1. You need to [get an account](https://portal.aws.amazon.com/billing/signup?client=quicksight&fid=441BE2A63D1F1F56-313F2AF2462BDF3C&redirect_url=https%3A%2F%2Fquicksight.aws.amazon.com%2Fsn%2Fconsole%2Fsignup#/start&refid=ha_awssm-evergreen-free_tier) for [AWS QuickSight](https://aws.amazon.com/quicksight). If you register successfully, you can see a page like this.

    ![quicksight account](/assets/quicksight-account.png)

2. Click the **Go to Amazon QuickSight**. It will jump to the [home page of AWS QuickSight](https://us-west-2.quicksight.aws.amazon.com/sn/start/analyses).

    ![quicksight homepage](/assets/quicksight-homepage.png)

3. Click the **Datasets** tab and the **New dataset**.

    ![datasets](/assets/datasets.png)

4. And you can select the **MySQL** card. Because TiDB is highly compatible with the MySQL protocol and supports [most MySQL syntax and features](https://docs.pingcap.com/tidb/stable/mysql-compatibility), most MySQL connection libraries are compatible with TiDB.

    ![mysql dataset type](/assets/mysql-dataset-type.png)

5. In the dialog, input your TiDB cluster message. And click the "Validate connection" button. AWS QuickSight will use the TiDB cluster properties you just input, try to connect the TiDB cluster.

    ![mysql data source](/assets/mysql-data-source.png)

6. It shows validated, then click the **Create data source** (If some errors occur, please check your TiDB cluster is available, and reachable to AWS QuickSight).

    ![validated](/assets/validated.png)

7. Then you can see the tables in the database you specify. Here I just click the **Select** for demonstration. You can edit/preview it, or use SQL to retrieve a result set. As an example we would choose the **fitness_trackers** table that we just created in TiDB Cloud Dedicated Tier cluster.

    ![table](/assets/table.png)

8. In this case I select the **Directly query your data** option, and click the **Visualize**.

    ![visualize](/assets/visualize.png)

9. Data is successfully imported. And you can just click these buttons. You can see a pie chart for "Total Percentage of the Fitness Tracker Brands".

    ![preview](/assets/preview.png)

You can see the [AWS QuickSight User Guide](https://docs.aws.amazon.com/quicksight/latest/user/welcome.html) to get more AWS QuickSight usage information.

## Noteworthy things

By the date this note was sent out, the TiDB Cloud Serverless Tier cluster can NOT be linked by a non-TLS connection. And TiDB Cloud Serverless Tier’s CA(Let's Encrypt) doesn't exist in the Amazon QuickSight trust list. So, you need to create a TiDB Cloud Dedicated Tier cluster or self-host cluster to avoid this issue.

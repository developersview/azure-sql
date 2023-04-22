
####### Importing CSV file into Azure Studio #######

# Click on the Manage button and then Click extensions From the Azure Data Studio Page
# Type @sort:installs  on the search bar --> This will display the extensions.
# Scroll down and find the "SQL Server import extension"
# And then click on "install" 

# Right Click on the database where you want to import the csv file (sql_database)
#       and click on "Import Wizard"
# Our server will be automatically selected
# Make sure for the field "Database the table is created in", sql_database is selected
# For the Location of the file to be imported, hit the browse button to choose a file (BIKE DETAILS.csv)
# Set the New table name to bike_details
# For the Table schema, choose SalesLT (we'll assume we're also selling bikes)

# Click on Next -> Click on "next" on the preview page 
# By default, it will set column names based on the header
# Data types will be set automatically based on the data itself 
# Heading to the next step (Modify Columns), we have the option to change the assigned types
# No changes are needed. Hit Import Data

# Click on "Done" Once Import file is completed 

# Refresh the Tables list 
# You can see newly created table (SalesLT.bike_details)

# Create a new query in Azure SQL 
# Run the below query 

SELECT *
FROM [SalesLT].[bike_details];


######### Aggregate Functions #########


# Max - without the AS keyword
SELECT MAX(selling_price) Max_Selling_Price  
FROM [SalesLT].[bike_details];   

# min - using the AS keyword
SELECT MIN(selling_price) AS Min_Selling_Price  
FROM [SalesLT].[bike_details];    

# STDEV, SUM, and COUNT
SELECT AVG(selling_price) AS Avg_Selling_Price,
       STDEV(selling_price) AS StdDev_Selling_Price,
       SUM(selling_price) AS Inventory_Value,
       COUNT(name) AS Bike_Count
FROM [SalesLT].[bike_details];   

 

# GROUPING

SELECT year, 
       AVG(selling_price) AS Avg_Selling_Price,
       SUM(selling_price) AS Inventory_Value
FROM [SalesLT].[bike_details]   
GROUP BY year; 

# ORDER BY
SELECT year, 
       AVG(selling_price) AS Avg_Selling_Price,
       SUM(selling_price) AS Inventory_Value
FROM [SalesLT].[bike_details]   
GROUP BY year
ORDER BY year; 



# WHERE
SELECT year,
       AVG(selling_price)AS Avg_Selling_Price,   
       AVG(km_driven) AS Avg_Km_Driven
FROM [SalesLT].[bike_details] 
WHERE year > 2007
GROUP BY year
ORDER BY year


SELECT year,
       AVG(selling_price) AS Avg_Selling_Price,   
       AVG(km_driven) AS Avg_Km_Driven
FROM [SalesLT].[bike_details] 
WHERE year > 2007
GROUP BY year
HAVING AVG(selling_price) > 100000
ORDER BY year


# Using COUNT and DISTINCT

SELECT COUNT(DISTINCT name) AS Distinct_Bike_Names
FROM [SalesLT].[bike_details];

# Using APPROX_COUNT_DISTINCT

SELECT APPROX_COUNT_DISTINCT(name) AS Approx_Distinct_Bike_Names
FROM [SalesLT].[bike_details];

# Using APPROX_COUNT_DISTINCT with GROUP BY 

SELECT year, APPROX_COUNT_DISTINCT(name) AS Approx_Distinct_Bike_Names
FROM [SalesLT].[bike_details]
GROUP BY year
ORDER BY year;




#############################################

######### Table Partitioning  #########

# let’s verify the Azure DB data file and its location using the sys.database_files
# We observe that there is a file for rows, one for logs, and another for filestream
# Observe columns such as size, max_size, is_read_only etc.

SELECT * FROM sys.database_files

## Check the partition functions currently in the system - there will be none
SELECT * FROM sys.partition_functions


# Let’s define a partition function and scheme before we create a partition table.

CREATE PARTITION FUNCTION [sales_year_pf] (datetime)
AS RANGE RIGHT FOR VALUES ('2010', '2011','2012',
                            '2013', '2014', '2015', '2016',
                            '2017', '2018', '2019','2020');



# Verify the partition function using the sys.partition_functions.
SELECT * FROM sys.partition_functions


# We can validate the partition function using the following query.
# It returns the partition number in which the data will be stored.

SELECT
InputValue,
$PARTITION.sales_year_pf(InputValue) AS Partition
FROM
(
VALUES
('19971105'),
('20090730'),
('20210730'),
('20260730'),
('20120521'),
('20150101'),
('20151231'),
('20160101'),
('20190101')
) AS TEST (InputValue);


# Partition scheme: 

## Check for existing schemes
SELECT * 
FROM sys.partition_schemes 

# The partition scheme maps a partition function to something called file groups, 
#       which is commonly used in SQL Server
# From the docs, "Because only the PRIMARY filegroup is supported in Azure SQL Database, 
#       all partitions must be placed on the PRIMARY filegroup"
# we use the argument – ALL TO PRIMARY, for mapping all partition boundaries to the primary file group
CREATE PARTITION SCHEME sales_year_pscheme
AS PARTITION sales_year_pf
ALL TO ([PRIMARY])

# Confirm creation of the scheme

SELECT * 
FROM sys.partition_schemes 



# Data insertion to the partition table is similar to a regular SQL table.
# However, internally, it splits data as defined boundaries in the PS function and PS scheme file group.

CREATE TABLE [SalesLT].[DemoPartitionTable]
(
ID int,
[Timestamp] datetime PRIMARY KEY,
[Sampletext] varchar(100)
)
ON sales_year_pscheme ([Timestamp]);



## Insert data into the table - one extra row at the bottom in comparison to the test done earlier
INSERT INTO [SalesLT].[DemoPartitionTable] (id, [TimeStamp],[SampleText])
SELECT '1', '19971105','Year 1997' UNION ALL
SELECT '1', '20090730','Year 2009' UNION ALL
SELECT '1', '20210730','Year 2021' UNION ALL
SELECT '2', '20260730','Year 2026' UNION ALL
SELECT '1', '20120521','Year 2012' UNION ALL
SELECT '1', '20150101','Year 2015' UNION ALL
SELECT '1', '20151231','Year 2015' UNION ALL
SELECT '1', '20160101','Year 2016' UNION ALL
SELECT '1', '20190101','Year 2019' UNION ALL
SELECT '1', '20170507','Year 2017';


# Let’s create partition number and number of rows in each partition for the Azure SQL Database table created earlier.

SELECT Partition_Number AS [Partition Number], 
       Row_Count AS NumberofRows
FROM sys.dm_db_partition_stats
WHERE object_id = object_id('SalesLT.DemoPartitionTable');


## Clean up
DROP TABLE [SalesLT].[DemoPartitionTable];
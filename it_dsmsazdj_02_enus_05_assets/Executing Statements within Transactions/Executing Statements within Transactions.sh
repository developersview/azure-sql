######### Local_Transaction ########

## We'll be making use of Transact-SQL commands in this demo
## https://en.wikipedia.org/wiki/Transact-SQL

## In Azure Data Studio, right-click on the sql_database from the left menu and choose "New Notebook"

# Click on "+Cell" -> Then Click on "Code Cell"
# Run the below query 

CREATE SCHEMA BookStore;

## We can add a cell using the keyboard shortcut
## Head to the Azure Data Studio menu at the top and choose Preferences --> Keyboard shortcuts
## Quickly scroll through the list but note to stop at "Run Cell"
## We'll now use keyboard shortcuts

## Hit Ctrl + Shift + C to add a new cell and paste in this Create Table command

CREATE TABLE [BookStore].[Books]
(
  id INT,
  book_title VARCHAR(50),
  genre VARCHAR(50),
  price FLOAT,
  year INT
);

## Hit F5 (fn + F5) to run the cell and create the table

## Can continue using keyboard shortcuts from now on if that is your preferred style

INSERT INTO [BookStore].[Books]
VALUES
(1, 'The Candy House', 'Science Fiction', 626.05, 2022),
(2, 'Fiona and Jane', 'Literary Fiction', 451.51 , 2022),
(3, 'To Paradise', 'Historical Fiction', 379.28, 2022),
(4, 'Book Lovers', 'Romance Novel', 223.25, 2022),
(5, 'The Living Mountain', 'Fiction', 116.65, 2022 ),
(6, 'Unfinished', 'Memoir,', 206.15, 2021),
(7, 'Matrix', 'Historical Fiction', 309.30, 2021),
(8, 'Beautiful Things', 'Biography', 407.55, 2021),
(9, 'Malibu Rising', 'Historical Fiction', 309.30, 2021);


# Right click on "Tables" from the left panel
# Now you can see our newly created table "Books" as [BookStore].[Books]
# Click on that -> click on "Columns" under that to check the table columns

# Now again click on "Cell" -> "Code Cell"
# On the new cell, Paste the below query and Run the query 

SELECT * FROM [BookStore].[Books];


######## 

#Executing multiple queries without using transactions

INSERT INTO [BookStore].[Books] 
VALUES (10, 'Gingerbread', 'Fairy Tale', 450, 2019);

UPDATE [BookStore].[Books] 
SET price = '5 Hundred' WHERE id = 10;

# As we didn't use the transaction, INSERT statement will execute and UPDATE Statement will throw an error
# So when we retrieve the data we can see Id 10 has been inserted, but not updated 

# Lets cross check
SELECT * FROM [BookStore].[Books];

########### 

# Automatically rollback SQL transactions

# If one of the queries in a group of queries executed inside a transaction fails, 
# all the previously executed SQL statements are roll backed

BEGIN TRANSACTION
 
  INSERT INTO [BookStore].[Books] 
  VALUES (11, 'The Water Dancer', 'Magical Realism', 350.46, 2019)
 
  UPDATE [BookStore].[Books]
  SET price = '5 Hundred' WHERE id = 11
 
COMMIT TRANSACTION

# It shows an error, as in the update statement we were given the wrong data type
# Lets see whether "insert" statement executed or not(like previous query )

SELECT * FROM [BookStore].[Books];

# We can see in the result, If there is any error inside the transaction,
# Whatever operation we have performed successfully inside the transaction will be automatically rolled back
# That is, a ROLLBACK operation will be performed on the successful operation

###### 

# Manually rollback SQL transactions

DECLARE @BookCount int
 
BEGIN TRANSACTION 
 
  INSERT INTO [BookStore].[Books]
  VALUES (10, 'The Water Dancer', 'Magical Realism', 350.46, 2019)
 
  SELECT @BookCount = COUNT(*) FROM [BookStore].[Books] WHERE id = 10
 
  IF @BookCount > 1
    BEGIN 
      ROLLBACK TRANSACTION 
      PRINT 'A book with the same id already exists'
    END
  ELSE
    BEGIN
      COMMIT TRANSACTION
      PRINT 'New book added successfully!'
    END

 # You will get an error, stating that the id already exists

 # But let's cross check 

SELECT * FROM [BookStore].[Books];

 # We can see that the new row did not get inserted


 ## Re-run the same transaction above, but this time with an id of 11
 ## The transaction goes through

DECLARE @BookCount int
 
BEGIN TRANSACTION 
 
  INSERT INTO [BookStore].[Books]
  VALUES (11, 'The Water Dancer', 'Magical Realism', 350.46, 2019)
 
  SELECT @BookCount = COUNT(*) FROM [BookStore].[Books] WHERE id = 11
 
  IF @BookCount > 1
    BEGIN 
      ROLLBACK TRANSACTION 
      PRINT 'A book with the same id already exists'
    END
  ELSE
    BEGIN
      COMMIT TRANSACTION
      PRINT 'New book added successfully!'
    END


## Confirm the insert
SELECT * FROM [BookStore].[Books];


 #########

# Naming the transaction 

DECLARE @BookCount int
 
BEGIN TRANSACTION AddBook
 
  INSERT INTO [BookStore].[Books]
  VALUES (10, 'The Andromeda Strain', 'Science Fiction', 499, 1969)
 
  SELECT @BookCount = COUNT(*) FROM [BookStore].[Books] WHERE id = 10
 
  IF @BookCount > 0
    BEGIN 
      ROLLBACK TRANSACTION AddBook
      PRINT 'A book with the same id already exists'
    END
  ELSE
    BEGIN
      COMMIT TRANSACTION AddBook
      PRINT 'New book added successfully!'
    END


######## 
# Save point 
# Also note how comments are written
  
BEGIN TRANSACTION 
 
   INSERT INTO [BookStore].[Books]
   VALUES (12, 'The Andromeda Strain', 'Science Fiction', 499, 1969)
   -- This will create a savepoint after the first INSERT
   SAVE TRANSACTION FirstInsert

   INSERT INTO [BookStore].[Books]
   VALUES  ( 13, 'The Dutch House', 'Historical Fiction', 342.30, 2019)

   SAVE TRANSACTION SecondInsert
 
   -- This will rollback to the savepoint right after the first INSERT
   ROLLBACK TRANSACTION FirstInsert

-- This will commit the transaction leaving just the first INSERT 
COMMIT



# Let's cross check 
SELECT * FROM [BookStore].[Books]

# From the output we can observed, 2 insert statements got executed, 
# But we cannot see the second one in the results - it got rolled back 

########

# In the next example, The transaction rolls back to the second save point whose name is set using a variable

DECLARE @vSecondInsert NCHAR(50) = 'SecondInsert'
 
BEGIN TRANSACTION 
 
   INSERT INTO [BookStore].[Books]
   VALUES  ( 13, 'The Dutch House', 'Historical Fiction', 342.30, 2019)
   SAVE TRANSACTION FirstInsert
 
   INSERT INTO [BookStore].[Books]
   VALUES  ( 14, 'The Nickel Boys', 'Historical Fiction', 299.48, 2019)
   SAVE TRANSACTION @vSecondInsert

   INSERT INTO [BookStore].[Books]
   VALUES  ( 15, 'Olive Again', 'Psychological Fiction', 309.13, 2019)
   SAVE TRANSACTION ThirdInsert
 
   ROLLBACK TRANSACTION @vSecondInsert 
   -- can also use ROLLBACK TRANSACTION SecondInsert
 
COMMIT

# We confirm the contents of the table - only the first 2 books have been inserted

SELECT * FROM [BookStore].[Books]

########## 

# Rolling Back to the SQL Server Save point and @@TRANCOUNT Variable
## https://learn.microsoft.com/en-us/sql/t-sql/functions/trancount-transact-sql

SELECT @@TRANCOUNT AS '1. - @@TRANCOUNT before starting the first transaction'
 
BEGIN TRANSACTION -- Tran 1
  SELECT @@TRANCOUNT AS '2. - @@TRANCOUNT after starting the first transaction'
  
  INSERT INTO [BookStore].[Books]
  VALUES  ( 15, 'Olive Again', 'Psychological Fiction', 309.13, 2019)
  SAVE TRANSACTION FirstInsert
   
  BEGIN TRANSACTION -- Tran 2
    SELECT @@TRANCOUNT AS '3. - @@TRANCOUNT after starting the second transaction'

    INSERT INTO [BookStore].[Books]
    VALUES  ( 16, 'American Spy', 'Thriller', null, 2019)
      
    ROLLBACK TRANSACTION FirstInsert
    SELECT @@TRANCOUNT AS '4. - @@TRANCOUNT after rolling back to the save point'
  
    BEGIN TRANSACTION -- Tran 3 
      SELECT @@TRANCOUNT AS '5. - @@TRANCOUNT after starting the third transaction'

      INSERT INTO [BookStore].[Books] 
      VALUES( 17, 'The Need', 'Suspense', 353.56, 2019)
 
      COMMIT -- Tran 3
      SELECT @@TRANCOUNT AS '6. - @@TRANCOUNT after committing the third transaction'
  
      SELECT * FROM [BookStore].[Books]
 
    COMMIT -- Tran 2
    SELECT @@TRANCOUNT AS '7. - @@TRANCOUNT after committing the second transaction'

  ROLLBACK -- Tran 1
  SELECT @@TRANCOUNT AS '8. - @@TRANCOUNT after rolling back the first transaction'


# In the output output, you can see, step by step, the results
## The SELECT query results showed that the 2nd insert had been rolled back at that point
# Also we will get to see the final output by executing the below query 

SELECT * FROM [BookStore].[Books]


############ 

# Error handling 
## The insert below will cause an error as a string 'N/A' is passed instead of price
## We'll get to see all the error information

BEGIN TRY

  BEGIN TRANSACTION

    INSERT INTO [BookStore].[Books]
    VALUES  ( 16, 'American Spy', 'Thriller', 'NA', 2019)
    COMMIT TRANSACTION
END TRY

BEGIN CATCH

  SELECT SUSER_SNAME() AS USER_NAME,
         ERROR_NUMBER() AS ERROR_NUMBER,
         ERROR_STATE() AS ERROR_STATE,
         ERROR_SEVERITY() AS ERROR_SEVERITY,
         ERROR_LINE() AS ERROR_LINE,
         ERROR_PROCEDURE() AS ERROR_PROCEDURE,
         ERROR_MESSAGE() AS ERROR_MESSAGE ,
         GETDATE() AS GETDATE;
 
  -- Transaction uncommittable
  IF (XACT_STATE()) = -1
    ROLLBACK TRANSACTION
 
  -- Transaction committable
  IF (XACT_STATE()) = 1
    COMMIT TRANSACTION

END CATCH


## The insert has not taken place

SELECT * FROM [BookStore].[Books]

###############

## We just set a valid value for the book price and run that block of code
## This time, the code does not enter the catch block

BEGIN TRY

  BEGIN TRANSACTION

    INSERT INTO [BookStore].[Books]
    VALUES  ( 16, 'American Spy', 'Thriller', null, 2019)
    COMMIT TRANSACTION
END TRY

BEGIN CATCH

  SELECT SUSER_SNAME() AS USER_NAME,
         ERROR_NUMBER() AS ERROR_NUMBER,
         ERROR_STATE() AS ERROR_STATE,
         ERROR_SEVERITY() AS ERROR_SEVERITY,
         ERROR_LINE() AS ERROR_LINE,
         ERROR_PROCEDURE() AS ERROR_PROCEDURE,
         ERROR_MESSAGE() AS ERROR_MESSAGE ,
         GETDATE() AS GETDATE;
 
  -- Transaction uncommittable
  IF (XACT_STATE()) = -1
    ROLLBACK TRANSACTION
 
  -- Transaction committable
  IF (XACT_STATE()) = 1
    COMMIT TRANSACTION

END CATCH


## Confirm the insert
SELECT * FROM [BookStore].[Books]


############## Logging messages from Azure Functions to Azure SQL Database

# By considering we already have sql database connected with Azure studio 
# Lets create a new table 

# Let us now create a simple table that can be used to store the log messages

CREATE SCHEMA log_details

CREATE TABLE [log_details].[ApplicationLogs](
    [Id]            [INT]            IDENTITY(1,1) NOT NULL,
    [LogMessage]    [NVARCHAR](MAX)  NULL,
    [CreateDate]    [DATETIME]       NULL,
    CONSTRAINT      [PK_Logs]        PRIMARY KEY CLUSTERED  ([Id] ASC)
 )
 
INSERT INTO [log_details].[ApplicationLogs] ([LogMessage],[CreateDate])
VALUES('This is a test log message.', GETDATE())
 
SELECT * FROM [log_details].[ApplicationLogs];



# Now from the SQL_DATABASE page 
# Click on "Connection String" from the left navigation menu 
# We need to replace the password with the one that we have set.

Server=tcp:loony-azure-sql-server.database.windows.net,1433;Initial Catalog=sql_database;Persist Security Info=False;User ID=loonyuser;Password=Loony_2021;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;

# With this, our database is ready to be used by the Azure Function now.

###### 
# Creating the Azure Function

# Type "Function App" on the search bar 
# From "Function App" page, Click on "Create Function App"
 # Resource group : "loony-azure-sql-rg"
 # Function App name : azure-sql-function
 # Publish : Code
 # Runtime Stack : Python 
 # Version : 3.9
 # Region : Central India 
 # OS : Linux
# Click on "Review + Create"-> click on "create"

######

# Create a new Function App

# Click on "Go to resource"
# On the Functions page
  #Click on "Functions" and then -> Click on "Create" :
  # Development environment : Develop in portal
  # Template : HTTP Trigger( Click on it)
  # Click on "Create"

# Once we Create the function code, you can view and test it.

# Click on "Code + Test" from Http Trigger1 
# Click on "Get Function URL"
# Copy the URL from the new pop-up box 
# and paste it into the address bar of your browser.

https://loony-azure-sql-rg.azurewebsites.net/api/HttpTrigger1?code=Wb8tgYQEwtWOQQt1ZTRjcChAb07yR_18-eo1I_L3qJv4AzFuvQHn3Q==

# or we can also modify the link as below

https://loony-azure-sql-rg.azurewebsites.net/api/HttpTrigger1?code=Wb8tgYQEwtWOQQt1ZTRjcChAb07yR_18-eo1I_L3qJv4AzFuvQHn3Q==&name=Loonycorn

################ 

# Lets install Visual Studio Code

https://code.visualstudio.com/docs/?dv=osx

# Download for mac os from the above link 
# Open the Visual Studio Code from the above link 
# Click on "Extension" from the left panel and install the below extension 

Python Extension for Visual Studio Code
# Click on "Reload" if required

Azure Functions Extension for Visual Studio Code

# open terminal and run the following commands
# Click on "terminal" from the top menu 

brew tap azure/functions

## Note that for the Azure Functions Core Tools, we'll need Xcode and XCode command line tools
##      on a MacOS
brew install azure-functions-core-tools@4

# if upgrading on a machine that has 2.x or 3.x installed:
brew link --overwrite azure-functions-core-tools@4

# Switch to Visual studio code 
# And Click on Azure Symbol from the left navigation menu 

# Click on  "Sign into to Azure Account"
# ( And sing in with user name and password )

# Click on "+" -> in front of "WORKSPACE" 
# Click on "CREATE FUNCTION" -> Then Click on Click on "Create new project" from the new dialog box 
# Click on "New Folder" -> Folder Name : "azure-sql-function"
# Click on "Create" -> Click on "Select"
# Select languages as : "Python"
# Version : python 3.7.3
# Template : HTTP Trigger 
# Template rename it as : "loony-http-trigger-function" ->  Press Enter to confirm 
#( Also Click on "Yes, I Trust the authors Trust folder and enable all features")
# Authorization level " Anonymous"
# Select "Open in current window"
# It will create a new function, Once it get created

# Click on "loony-http:trigger-function" from the left panel
# Function code will appear in the editor section

# Now click in "Run and Debug" from the left panel
# Click on "Attach to python function" from the top of the page 
# Click on "Green Play Button to start debug ( It will run)
# Once it runs successfully, Copy the Function URL and paste it in the new browser

http://localhost:7071/api/loony-http-trigger-function

# We can also give the name parameter
http://localhost:7071/api/loony-http-trigger-function?name=Loonycorn

# Observe on the Visual studio code terminal to see the logs 

# Click on "Disconnect icon" at the top 
# Close the terminal 

#######

# To install Microsoft ODBC driver 18 for SQL Server on macOS, run the following commands:

brew tap microsoft/mssql-release \
    https://github.com/Microsoft/homebrew-mssql-release

brew update

ACCEPT_EULA=Y brew install msodbcsql18 mssql-tools18

brew link mssql-tools18

# Setting up python for connecting with Azure SQl

# install pyodbc

# https://docs.microsoft.com/en-us/sql/connect/python/pyodbc/step-1-configure-development-environment-for-pyodbc-python-development?view=sql-server-ver16

pip install pyodbc

# Paste the code in the Visual studio editor 

import pyodbc 
import logging
import azure.functions as func
from datetime import datetime

def main(req: func.HttpRequest) -> func.HttpResponse:

    logging.info('Setting up a connection to sql_database')
    server = 'loony-azure-sql-server.database.windows.net' 
    database = 'sql_database' 
    username = 'loonyuser' 
    password = 'Loony_2021' 
    
    cnxn = pyodbc.connect('DRIVER={ODBC Driver 18 for SQL Server};SERVER='
                            +server+';DATABASE='+database+';UID='+username+';PWD='+ password)
    print("Established connection")
    cursor = cnxn.cursor()
    
    name = req.params.get('name')
    if not name:
        try:
            req_body = req.get_json()
        except ValueError:
            pass
        else:
            name = req_body.get('name')

    if name:
        date_time = datetime.today().strftime('%Y-%m-%d %H:%M:%S')
        count = cursor.execute("""INSERT INTO [log_details].[ApplicationLogs] 
                                  ([LogMessage],[CreateDate])
                                  VALUES(?,?)""", 
                                  name,date_time)
        cnxn.commit()
        print('Rows inserted' + str(count))
        
        cursor.execute('SELECT * FROM [log_details].[ApplicationLogs];')
        row = cursor.fetchone()
        while row:
            print(row)
            row = cursor.fetchone()
        return func.HttpResponse(f"Hello, {name}. This HTTP triggered function executed successfully.")
    else:
        return func.HttpResponse(
             "This HTTP triggered function executed successfully. Pass a name in the query string or in the request body for a personalized response.",
             status_code=200
        )

  # And make sure this editor is under workspace/loony-function

  # Click on "Deploy" icon ( Icon looks like cloud, it is under workspace section)
  # click on "Attach to python function"(Play button)

 # Paste the URL link in the new browser, with the name which you would like to give

 http://localhost:7071/api/loony-http-trigger-function?name=Alice 

 # Also switch to Azure Data Studio console 
 # And run the below query 

# Here you can see the new row which you have mentioned in browser window 

SELECT * FROM [log_details].[ApplicationLogs]



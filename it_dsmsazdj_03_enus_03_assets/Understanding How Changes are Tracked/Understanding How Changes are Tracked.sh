########### Monitoring Data Changes


## Change data capture is not available for the Basic tier of Azure SQL Database
## We'll need to change our pricing tier to test out this feature
## Head over to the Azure portal and navigate to the sql_database resource
## Under "Pricing tier", click on the Basic link

## Select the "Service tier" to be General Purpose (Scalable compute and storage options)
## For the Compute tier, opt for Serverless
## Leave all other settings at their default values
## Scroll down and hit Apply

## The database will then need to be scaled - this can take several minutes
## Once it's done, head to Azure Data Studio and work from a new notebook

## From this point on, refer to the notebook ChangeDataCapture.ipynb

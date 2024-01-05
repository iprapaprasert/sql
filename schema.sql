-- create schema
CREATE SCHEMA WelfareCard AUTHORIZATION dbo

-- ALTER SCHEMA
--- Transferring ownership of a table
USE AdventureWorks2022;
GO
ALTER SCHEMA HumanResources TRANSFER Person.Address;
GO
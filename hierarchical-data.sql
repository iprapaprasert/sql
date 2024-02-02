-- parent/child hierarchy approach
USE AdventureWorks2022;
GO

CRAETE TABLE ParentChildOrg (
    BusinessEntityID int PRIMARY KEY,
    ManagerID int REFERENCES ParentChildOrg(BusinessEntityID),
    EmployeeName nvarchar(50)
);
GO
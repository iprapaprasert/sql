-- Lesson 1: Converting Table to a Hierarchical Structure
--- Examine the Current Structure of the Employee Table
---- Copy the Employee table
USE AdventureWorks2022;
GO

IF OBJECT_ID('HumanResources.EmployeeDemo') IS NOT NULL
DROP TABLE HumanResources.EmployeeDemo

SELECT emp.BusinessEntityID EmployeeID,
	   emp.LoginID, 
	   (SELECT man.BusinessEntityID
		  FROM HumanResources.Employee man
	     WHERE emp.OrganizationNode.GetAncestor(1) = man.OrganizationNode 
		    OR (emp.OrganizationNode.GetAncestor(1) = 0x AND man.OrganizationNode IS NULL)
	   ) AS ManagerID,
	   emp.JobTitle,
	   emp.HireDate
INTO HumanResources.EmployeeDemo
FROM HumanResources.Employee emp;
GO
---- Examine the structure and data of the EmployeeDemo table
SELECT Mgr.EmployeeID MgrID, Mgr.LoginID Manager, Emp.EmployeeID E_ID, Emp.LoginID, Emp.JobTitle
  FROM HumanResources.EmployeeDemo Emp
  LEFT JOIN HumanResources.EmployeeDemo Mgr
    ON Emp.ManagerID = Mgr.EmployeeID
 ORDER BY MgrID, E_ID

--- Populate a Table with Existing Hierarchical Data
---- To create a new table named NewOrg
CREATE TABLE HumanResources.NewOrg (
	OrgNode hierarchyid,
	EmployeeID int,
	LoginID nvarchar(50),
	ManagerID int
	CONSTRAINT PK_NewOrg_OrgNode PRIMARY KEY CLUSTERED (OrgNode)
);
GO
---- Create a temporary table named #Children
CREATE TABLE #Children (
	EmployeeID int,
	ManagerID int,
	Num int
);
GO
CREATE CLUSTERED INDEX tempind ON #Children(ManagerID, EmployeeID);
GO
---- Populate the NewOrg table
INSERT #Children (EmployeeID, ManagerID, Num)
SELECT EmployeeID, ManagerID, 
       ROW_NUMBER() OVER (PARTITION BY ManagerID ORDER BY ManagerID)
FROM HumanResources.EmployeeDemo;

SELECT * FROM #Children ORDER BY ManagerID, Num;

WITH paths(path, EmployeeID) AS (
	 -- This section provides the value for the root of the hierarchy
	 SELECT hierarchyid::GetRoot() AS OrgNode, 
	        EmployeeID
	   FROM #Children AS C
	  WHERE ManagerID IS NULL

	  UNION ALL
	 -- This section provides values for all nodes except the root
	 SELECT CAST(p.path.ToString() + CAST(C.Num AS varchar(30)) + '/' AS hierarchyid),
	        C.EmployeeID
	   FROM #Children AS C
	   JOIN paths AS p
	     ON C.ManagerID = P.EmployeeID
)
INSERT HumanResources.NewOrg(OrgNode, O.EmployeeID, O.LoginID, O.ManagerID)
SELECT P.path, O.EmployeeID, O.LoginID, O.ManagerID
  FROM HumanResources.EmployeeDemo AS O
  JOIN Paths AS P
    ON O.EmployeeID = P.EmployeeID;
GO

SELECT OrgNode.ToString() AS LogicalNode, *
  FROM HumanResources.NewOrg
 ORDER BY LogicalNode;
 GO

DROP TABLE #Children;
GO

--- Optimizing the NewOrg Table
---- Create index on NewOrg table for efficient searches
 ALTER TABLE HumanResources.NewOrg
   ADD H_Level AS OrgNode.GetLevel();
CREATE UNIQUE INDEX EmpBFInd
    ON HumanResources.NewOrg(H_Level, OrgNode);
GO

CREATE UNIQUE INDEX EmpID_unq ON HumanResources.NewOrg(EmployeeID);
GO

SELECT OrgNode.ToString() AS LogicalNode,
       OrgNode, H_Level, EmployeeID, LoginID
  FROM HumanResources.NewOrg
 ORDER BY OrgNode;

SELECT OrgNode.ToString() AS LogicalNode,
       OrgNode, H_Level, EmployeeID, LoginID
  FROM HumanResources.NewOrg
 ORDER BY H_Level, OrgNode;

SELECT OrgNode.ToString() AS LogicalNode,
       OrgNode, H_Level, EmployeeID, LoginID
  FROM HumanResources.NewOrg
 ORDER BY EmployeeID;

---- Drop the unneccessary columns
ALTER TABLE HumanResources.NewOrg DROP COLUMN ManagerID;
GO
DROP INDEX EmpIDs_unq ON HumanResources.NewOrg;
ALTER TABLE HumanResources.NewOrg DROP COLUMN EmployeeID;
GO

---- Replace the original table with the new table
DROP TABLE HumanResources.EmployeeDemo;
GO
sp_rename 'HumanResources.NewOrg', 'EmployeeDemo';
GO

SELECT * FROM HumanResources.EmployeeDemo;


-- Lesson 2: Create and Manage Data in a Hierarchical Table
--- Create the EmployeeOrg table
USE AdventureWorks2022;
GO

IF OBJECT_ID('HumanResources.EmployeeOrg') IS NOT NULL
	DROP TABLE HumanResources.EmployeeOrg

CREATE TABLE HumanResources.EmployeeOrg(
	OrgNode hierarchyid PRIMARY KEY CLUSTERED,
	OrgLevel AS OrgNode.GetLevel(),
	
)
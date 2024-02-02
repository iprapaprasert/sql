-- Convert latitude longitude into point
MerchantPoint = geography::Point(MerchantLatitude, MerchantLongitude, 4326)

-- Create table
CREATE TABLE Klk4.MerchantTransaction2 (
	TransactionDateTime datetime, 
	CitizenID nchar(13), 
	MerchantID nchar(20), 
	MerchantPoint geography, -- newly create field 
	CustomerPoint geography, -- newly create field
	ProvinceID nchar(2), -- we strictly map merchant location to the area
	CustomerPaidAmt money,
	GovtPaidAmt money
);

-- Convert point into province id
INSERT INTO Klk4.MerchantTransaction2 
SELECT *
FROM (
	SELECT 
		point.TransactionDateTime, 
		point.CitizenID, 
		point.MerchantID, 
		point.MerchantPoint, -- newly create field 
		point.CustomerPoint, -- newly create field
		poly.ProvinceID, -- we strictly map merchant location to the area
		point.CustomerPaidAmt,
		point.GovtPaidAmt
	FROM
		(
			SELECT
				TransactionDateTime,
				CitizenID,
				MerchantID,
				MerchantPoint = CASE 
					WHEN MerchantLatitude IS NULL OR MerchantLongitude IS NULL 
					THEN NULL 
					ELSE geography::Point(MerchantLatitude, MerchantLongitude, 4326) 
					END,
				CustomerPoint = CASE 
					WHEN CustomerLatitude IS NULL OR CustomerLongitude IS NULL 
					THEN NULL 
					ELSE geography::Point(CustomerLatitude, CustomerLongitude, 4326) 
					END,
				CustomerPaidAmt,
				GovtPaidAmt
			FROM HalfHalf.Klk4.MerchantTransaction
		) AS point
	LEFT JOIN Spatial.Gistda.ProvinceShape poly
	ON poly.Geog.STContains(point.MerchantPoint) = 1
) AS txn
-- Add column MerchantPoint
ALTER TABLE Klk4.ActiveMerchant
ADD MerchantPoint Geography;
GO

-- Add spatial index
CREATE SPATIAL INDEX SIndx_ActiveMerchant4_MerchantPoint
ON Klk4.ActiveMerchant(MerchantPoint);
GO

-- Update MerchantPoint in MerchantPoint Column
UPDATE Klk4.ActiveMerchant
SET MerchantPoint = 
    CASE 
        WHEN MerchantLatitude IS NULL OR MerchantLongitude IS NULL 
		THEN NULL 
	    ELSE geography::Point(MerchantLatitude, MerchantLongitude, 4326) 
	END;
GO

-- Add column ProvinceID
ALTER TABLE Klk4.ActiveMerchant
ADD ProvinceID int;
GO

-- Find ProvinceID
UPDATE Klk4.ActiveMerchant
SET ProvinceID =
    (SELECT ProvinceID
    FROM Spatial.Gistda.ProvinceShape poly WITH(INDEX(SI_ProvinceShape))
    WHERE poly.Geog.STIntersects(MerchantPoint) = 1);
GO
/*
link to file: https://github.com/Kimani-99/Portfolio-Projects/blob/main/Nashville_Housing_Data_for_Data%20Cleaning.csv
*/

/*

Cleaning Data in SQL

*/

SELECT *
FROM Portfolio.dbo.NashvilleHousing
-----------------------------------------------------------------------------------------------------------------

-- Populate Property Address

SELECT *
FROM Portfolio.dbo.NashvilleHousing
WHERE PropertyAddress is NULL

/*
It is observed that there are a fe null values for the property adddress. To Fill out these null values we i will
make reference to the property's parcel ID. thsi is so because Properties with the same parcel ID will have the 
the same property address. To begin we will do a self join to look at the table to itself to know if the parcel 
IDs are the same the n property address is the same.
*/

--The Following Query will allow us to view the tables without updating

SELECT A.ParcelID, A.PropertyAddress, B.ParcelID, B.PropertyAddress  -- We are interteded in the ParcelID and Property Address so we select those.
FROM Portfolio.dbo.NashvilleHousing AS A    --Aliasing for ease of reference
JOIN Portfolio.dbo.NashvilleHousing AS B    --Joining the table to itself. We are also Aliasing
    ON A.ParcelID = B.ParcelID              -- Joining on ParcelID. This way we are able to to compare parcelID and Property addresss to possibly fill out the missing information
    AND A.UniqueID <> B.UniqueID            -- Prevent Repetition of rows we also join on the Unique IDs not being equal
WHERE A.PropertyAddress is NULL             -- We to condition on table A property address being Null so that we can see what the address should be by looking at table B

--We are now running the A similiary query with ISNULL to pipulate the values for null
SELECT A.ParcelID, A.PropertyAddress, B.ParcelID, B.PropertyAddress, ISNULL(A.PropertyAddress, B.PropertyAddress) --ISNULL is saying that if Property address from tabel A is null, then we want 
                                                                                                                  --the want to populate it with the property address form table B
FROM Portfolio.dbo.NashvilleHousing AS A 
JOIN Portfolio.dbo.NashvilleHousing AS B 
    ON A.ParcelID = B.ParcelID
    AND A.UniqueID <> B.UniqueID
WHERE A.PropertyAddress is NULL

--Now we will be writing our update
UPDATE A
SET PropertyAddress = ISNULL(A.PropertyAddress, B.PropertyAddress)
FROM Portfolio.dbo.NashvilleHousing AS A 
JOIN Portfolio.dbo.NashvilleHousing AS B 
    ON A.ParcelID = B.ParcelID
    AND A.UniqueID <> B.UniqueID
WHERE A.PropertyAddress is NULL


--Now that we have made our update, lets see if it worked
SELECT A.PropertyAddress
FROM Portfolio.dbo.NashvilleHousing A
WHERE PropertyAddress is NULL -- Now that we made the updates we should not get any rows becasue of the where statement. Thus, it worked

-----------------------------------------------------------------------------------------------------------------

-- Breaking out Address into individual Columns (Address, City, State)

SELECT PropertyAddress, OwnerAddress
FROM Portfolio.dbo.NashvilleHousing

-- The following is looking at the propery address starting at the first value to the comma
-- it is also looking athe the property address from the comma to the end 
SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) AS StreetAddress, --the -1 is added so that the comma is not included in the output
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) as City --the +1 is added so that we start after the comma so that it is not included

FROM Portfolio.dbo.NashvilleHousing

-- We are now going to create two new columns for street address and City
ALTER TABLE NashvilleHousing
ADD PropertyStreetAddress NVARCHAR(255)

UPDATE NashvilleHousing
SET PropertyStreetAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)


ALTER TABLE NashvilleHousing
ADD PropertyCity NVARCHAR(255)

UPDATE NashvilleHousing
SET PropertyCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) 


--Viewing our updated table
SELECT *
FROM Portfolio.dbo.NashvilleHousing



--Splitting OwnerAddress using Parsename. parsename recognizes periods so we will have to change the commmas
--to periods. Additionally, parsename works backwards.
SELECT 
PARSENAME(REPLACE(OwnerAddress, ',', '.') ,3),
PARSENAME(REPLACE(OwnerAddress, ',', '.') ,2),
PARSENAME(REPLACE(OwnerAddress, ',', '.') ,1)
FROM Portfolio.dbo.NashvilleHousing

-- We are now going to create three new columns for Owner street address, city and state

ALTER TABLE NashvilleHousing
ADD OwnerStreetAddress NVARCHAR(255)

UPDATE NashvilleHousing
SET OwnerStreetAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') ,3)

ALTER TABLE NashvilleHousing
ADD OwnerCity NVARCHAR(255)

UPDATE NashvilleHousing
SET OwnerCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') ,2)

ALTER TABLE NashvilleHousing
ADD OwnerState NVARCHAR(255)

UPDATE NashvilleHousing
SET OwnerState = PARSENAME(REPLACE(OwnerAddress, ',', '.') ,1)

--Viewing Table to see if the chnages were made
SELECT *
FROM Portfolio.dbo.NashvilleHousing

-----------------------------------------------------------------------------------------------------------------

--Changing Y and N to Yes and No in "Sold as Vacant" field

SELECT APPROX_COUNT_DISTINCT(SoldAsVacant) --This will tell us how many differing Values are in the SoldAsVacant Column
FROM NashvilleHousing

--Here we will be able to see wthat those 4 differing responses are and how many of each there are
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant) 
FROM Portfolio.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER by 2

SELECT SoldAsVacant,
CASE When SoldAsVacant = 'Y' THEN 'Yes'
        When SoldAsVacant = 'N' THEN 'No'
        ELSE SoldAsVacant
        END
FROM Portfolio.dbo.NashvilleHousing


UPDATE NashvilleHousing
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' THEN 'Yes'
        When SoldAsVacant = 'N' THEN 'No'
        ELSE SoldAsVacant
        END


-- Checking to see if the changes were made
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant) 
FROM Portfolio.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER by 2

-----------------------------------------------------------------------------------------------------------------

--Removing Duplicates

WITH RowNumCTE AS(
Select *,
    ROW_NUMBER() OVER (
    PARTITION BY ParcelID,
                PropertyAddress,
                SalePrice,
                SaleDate,
                LegalReference
                ORDER BY
                    UniqueID 
    ) row_num
FROM Portfolio.dbo.NashvilleHousing
--ORDER BY ParcelID
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress

/*
In the above Querywe used CTC to create a table that will show us all the duplicates in the NashvilleHousing table.
We identified duplices by their parcelID, Property Address, Sale pride, Sale date and legal reference.
*/


--Deleting duplicates
WITH RowNumCTE AS(
Select *,
    ROW_NUMBER() OVER (
    PARTITION BY ParcelID,
                PropertyAddress,
                SalePrice,
                SaleDate,
                LegalReference
                ORDER BY
                    UniqueID 
    ) row_num
FROM Portfolio.dbo.NashvilleHousing
--ORDER BY ParcelID
)
DELETE 
FROM RowNumCTE
WHERE row_num > 1

-----------------------------------------------------------------------------------------------------------------

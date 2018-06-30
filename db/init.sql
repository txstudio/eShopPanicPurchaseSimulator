--docker run -e 'ACCEPT_EULA=Y' -e 'SA_PASSWORD=Pa$$w0rd' -p 1433:1433 -d --name eshop-mssql-srv microsoft/mssql-server-linux

/*
--將既有 eShop 資料庫移除的指令碼
EXEC msdb.dbo.sp_delete_database_backuphistory @database_name = N'eShop'

GO
USE [master]
GO

ALTER DATABASE [eShop]
	SET SINGLE_USER WITH ROLLBACK IMMEDIATE
GO

USE [master]
GO

DROP DATABASE [eShop]
GO
*/
/*
--重設資料內容指令碼

--設定商品庫存量
UPDATE [Products].[ProductStorages]
	SET [Storage] = 100
WHERE [ProductNo] = 1
GO

--移除訂單資訊
DELETE FROM [Orders].[OrderDetails]
DELETE FROM [Orders].[OrderMains]
GO
*/
CREATE DATABASE [eShop]
GO

USE [eShop]
GO

CREATE SCHEMA [Products]
GO

CREATE SCHEMA [Orders]
GO

--SCHEMA: Products
CREATE TABLE [Products].[ProductMains]
(
	[No]			INT,
	[Schema]		VARCHAR(15),
	[Name]			NVARCHAR(50),
	[SellPrice]		SMALLMONEY,
	
	CONSTRAINT [pk_Products_ProductMains] PRIMARY KEY ([No]),
	
	CONSTRAINT [un_Products_ProductMains_Schema] UNIQUE ([Schema])
)
GO

INSERT INTO [Products].[ProductMains] ([No],[Schema],[Name],[SellPrice])
	VALUES (1,'DYAJ93A900929IK',N'Apple iPhone X (256G)',36999)
GO

CREATE TABLE [Products].[ProductStorages]
(
	[ProductNo]		INT,
	[Storage]		SMALLINT,
	
	CONSTRAINT [pk_ProductStorages] PRIMARY KEY ([ProductNo]),
	
	CONSTRAINT [fk_ProductStorages_ProductNo] FOREIGN KEY ([ProductNo])
		REFERENCES [Products].[ProductMains]([No]) 
			ON DELETE NO ACTION 
			ON UPDATE NO ACTION
)
GO

INSERT INTO [Products].[ProductStorages] ([ProductNo],[Storage])
	VALUES (1,1000)
GO

--SCHEMA: Orders
CREATE SEQUENCE [Orders].[OrderMainSeq]
	START WITH 1
	INCREMENT BY 1
GO

CREATE TABLE [Orders].[OrderMains]
(
	[No]			INT,
	[Schema]		CHAR(15),
	
	[MemberGUID]	UNIQUEIDENTIFIER,
	[IsDeleted]		BIT,
	
	CONSTRAINT [pk_OrderMains] PRIMARY KEY ([No]),
	
	CONSTRAINT [un_OrderMains_Schema] UNIQUE ([Schema])
)

CREATE TABLE [Orders].[OrderDetails]
(
	[OrderNo]		INT,
	[ProductNo]		INT,
	
	[SellPrice]		SMALLMONEY,
	[Quantity]		SMALLINT,
	
	CONSTRAINT [pk_OrderDetails] PRIMARY KEY ([OrderNo],[ProductNo]),
	
	CONSTRAINT [fk_OrderDetails_OrderNo] FOREIGN KEY ([OrderNo])
		REFERENCES [Orders].[OrderMains] ([No]) 
			ON DELETE NO ACTION 
			ON UPDATE NO ACTION,
			
	CONSTRAINT [fk_OrderDetails_ProductNo] FOREIGN KEY ([ProductNo])
		REFERENCES [Products].[ProductMains] ([No]) 
			ON DELETE NO ACTION 
			ON UPDATE NO ACTION
)
GO

--Function

--取得新一筆訂單的訂單編號
CREATE FUNCTION [Orders].[GetOrderSchema]()
	RETURNS CHAR(15)
AS
BEGIN
	DECLARE @Schema CHAR(15)
	DECLARE @LastCode CHAR(8)
	DECLARE @LastIdentity CHAR(7)
	DECLARE @NewCode CHAR(8)
	DECLARE @Identity INT

	-- SET @Schema = (
		-- SELECT TOP(1) [Schema] FROM [Orders].[OrderMains]
		-- ORDER BY [No] DESC
	-- )
	SET @Schema = (
		SELECT TOP(1) [Schema] FROM [Orders].[OrderMains]
		ORDER BY [Schema] DESC
	)

	SET @NewCode = CONVERT(VARCHAR,GETDATE(),112)
	SET @LastCode = LEFT(@Schema,8)
	SET @LastIdentity = RIGHT(@Schema,7)

	SET @Identity = 0

	If @NewCode = @LastCode 
		SET @Identity = CONVERT(INT,@LastIdentity)

	SET @Identity = @Identity + 1

	RETURN (@NewCode + RIGHT('000000'+CONVERT(VARCHAR(7),@Identity),7))
END
GO

--取得指定商品型號的有效庫存
CREATE FUNCTION [Products].[GetProductValidStorage]
(
	@Schema			VARCHAR(15)
)
RETURNS SMALLINT
AS
BEGIN
	/*
	取得商品目前庫存	
	取得訂單的庫存	
	
	目前庫存減訂單庫存 = 可銷售數量
	*/
	DECLARE @ProductNo		INT
	DECLARE @ProductStorage	SMALLINT
	DECLARE @OrderStorage	SMALLINT
	DECLARE @Storage		SMALLINT
	
	SET @ProductNo = (
		SELECT [No] FROM [Products].[ProductMains]
		WHERE [Schema] = @Schema
	)
	
	IF @ProductNo IS NULL
	BEGIN
		RETURN (0)
	END
	
	
	SET @ProductStorage = (
		SELECT [Storage] FROM [Products].[ProductStorages]
		WHERE [ProductNo] = @ProductNo
	)
	
	SET @OrderStorage = (
		SELECT SUM([Quantity]) FROM [Orders].[OrderDetails]
		WHERE [ProductNo] = @ProductNo
	)
	
	SET @Storage = ISNULL(@ProductStorage,0) - ISNULL(@OrderStorage,0)
	
	IF @Storage > 0
	BEGIN
		RETURN @Storage
	END
	
	RETURN 0
END
GO

CREATE TYPE [Orders].[OrderDetails]
	AS TABLE
	(
		[ProductNo]		INT,
		[SellPrice]		SMALLMONEY,
		[Quantity]		SMALLINT
	)
GO

CREATE PROCEDURE [Orders].[AddOrder]
	@MemberGUID		UNIQUEIDENTIFIER,
	@Items 			[Orders].[OrderDetails] READONLY,
	@IsSuccess		BIT OUT
AS

	--超賣 / 5xxx ms
	--不指定 ISOLATION LEVEL

	--超賣 - 序號與訂單編號正確 / 速度最快 / 有機會超賣
	--SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	--超賣 - 序號會亂跳 / 訂單編號順序正確
    --SET TRANSACTION ISOLATION LEVEL READ COMMITTED
	
	--超賣 - 序號與訂單編號會錯亂
    --SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
    
	--不會超賣 - 序號會亂跳 / 訂單編號順序正確 - 用這個需額外設定 
	--SET TRANSACTION ISOLATION LEVEL SNAPSHOT
    
	--不會超賣 - 序號會亂跳 / 訂單編號順序正確 / 但是速度超慢
	--SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		DECLARE @OrderNo INT
		DECLARE @Schame CHAR(15)
		DECLARE @output TABLE (
			[ProductNo]		INT PRIMARY KEY,
			[AfterStorage]	SMALLINT
		)
		
		SET @IsSuccess = 1	
		
		--直接更新指定商品庫存
		UPDATE [Products].[ProductStorages]
			SET [Storage] = ([Storage] - [Quantity])
		OUTPUT deleted.[ProductNo]
			,inserted.[Storage]
		INTO @output
			FROM [Products].[ProductStorages] a 
				INNER JOIN @tables b ON a.[ProductNo] = b.[ProductNo]
		
		--若有商品庫存量小於購買數量
		--	取消此筆交易
		IF EXISTS(
			SELECT [ProductNo] 
			FROM @output 
			WHERE [AfterStorage] < 0
		)
		BEGIN
			ROLLBACK
		
			RETURN
		END
					
		SET @OrderNo = NEXT VALUE FOR [Orders].[OrderMainSeq]		
		SET @Schame = (
			SELECT [Orders].[GetOrderSchema]()
		)
	
		INSERT INTO [Orders].[OrderMains] (
			[No]
			,[Schema]
			,[MemberGUID]
			,[IsDeleted]
		) VALUES (
			@OrderNo,
			@Schame,
			@MemberGUID,
			0
		)
		
		INSERT INTO [Orders].[OrderDetails] (
			[OrderNo]
			,[ProductNo]
			,[SellPrice]
			,[Quantity]
		) SELECT @OrderNo
			,[ProductNo]
			,[SellPrice]
			,[Quantity]
		FROM @Items	
	
		COMMIT
	END TRY
	
	BEGIN CATCH	
		ROLLBACK
		
		SET @IsSuccess = 0
	END CATCH
GO
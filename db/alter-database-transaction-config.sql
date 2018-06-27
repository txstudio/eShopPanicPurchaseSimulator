/*
	此設定與 Azure SQL Database 相同
	https://blogs.msdn.microsoft.com/sqlcat/2013/12/26/be-aware-of-the-difference-in-isolation-levels-if-porting-an-application-from-windows-azure-sql-db-to-sql-server-in-windows-azure-virtual-machine/
*/

--啟用 SNAPSHOT_ISOLATION
ALTER DATABASE eShop  
	SET ALLOW_SNAPSHOT_ISOLATION ON

--啟用 READ_COMMITTED_SNAPSHOT
ALTER DATABASE eShop  
	SET READ_COMMITTED_SNAPSHOT ON
	WITH ROLLBACK IMMEDIATE

--檢視資料庫異動結果
SELECT a.database_id
	,a.name
	,a.snapshot_isolation_state
	,a.snapshot_isolation_state_desc
	,a.is_read_committed_snapshot_on
FROM sys.databases a
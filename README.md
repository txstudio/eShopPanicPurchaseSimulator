# 模擬電子商務網站搶訂商品的專案 / 目前程式碼方向錯誤

## 此說明尚未完成 / 程式碼已可以使用

此專案為模擬電子商務網站遇到多使用者搶訂商品的情境

專案環境
- Microsoft SQL Server 
- .NET Core 2.1 Console Application

資料夾中會準備建立範例資料庫使用的 Transact-SQL 指令碼

資料庫使用由 Docker Image 建立的 Microsoft SQL Server in Linux 資料庫，建立之指令碼如下
```
docker run -e 'ACCEPT_EULA=Y' -e 'SA_PASSWORD=Pa$$w0rd' -p 1433:1433 -d --name eshop-mssql-srv microsoft/mssql-server-linux
```

### 資料庫說明

|資料庫物件|類型|說明|
|--|--|--|
|Products.ProductMains|資料表|商品主資料表|
|Products.ProductStorages|資料表|商品庫存量資料表|
|Orders.OrderMains|資料表|訂單主資料表|
|Orders.OrderDetails|資料表|訂單商品詳細資料|
|Orders.OrderMainSeq|序列|訂單主索引鍵序號使用|
|Orders.GetOrderSchema|使用者自訂方法|取得新一筆訂單的訂單編號|
|Products.GetProductValidStorage|使用者自訂方法|取得指定商品的有效庫存|
|Orders.AddOrder|預存程序|建立訂單使用|
|Orders.OrderDetails|使用者自訂資料表型態|建立訂單時使用型態|

訂單將透過 Orders.AddOrder 預存程序建立，程式碼有保留指定各種交易隔離層級的指令碼

### 程式碼說明

專案程式碼為使用 .NET Core 2.1 版本開發之主控台應用程式專案，並可透過參數指定要建立的執行緒數量與啟用時間

可透過下列指令碼啟用 eShop.DbLoader 主控台應用程式：
```
dotnet eShop.DbLoader.dll -task 100 -minute 55
```
- task 為模擬的執行緒數量
- minute 為指定分鐘數過後所有啟用的執行緒開始呼叫

### 結果說明

設定 ISOLATION LEVEL 為 SERIALIZABLE 可避免不會超賣的情況發生，但是執行時間最久

### 參考資料
- [設定交易隔離的 T-SQL 指令碼](https://docs.microsoft.com/en-us/sql/t-sql/statements/set-transaction-isolation-level-transact-sql)
- [Azure Database 與 SQL Server 預設交易隔離層級不同的設定說明](https://blogs.msdn.microsoft.com/sqlcat/2013/12/26/be-aware-of-the-difference-in-isolation-levels-if-porting-an-application-from-windows-azure-sql-db-to-sql-server-in-windows-azure-virtual-machine/)
- [Read Committed Snapshot，NOLOCK 的另一個選擇](https://dotblogs.com.tw/rainmaker/2015/07/09/151792)

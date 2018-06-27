using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Text;

namespace eShop.DbLoader
{

    public sealed class eShopRepository
    {
        private string _connectionString;

        public eShopRepository()
        {
            var _builder = new SqlConnectionStringBuilder();
            _builder.DataSource = "192.168.0.80";
            _builder.InitialCatalog = "eShop";
            _builder.UserID = "sa";
            _builder.Password = "Pa$$w0rd";

            this._connectionString = _builder.ConnectionString;
        }

        public int GetStorageBySchema(string schema)
        {
            using (SqlConnection _conn
                = new SqlConnection(this._connectionString))
            {
                SqlCommand _cmd;
                int _storage;

                _cmd = new SqlCommand();
                _cmd.Connection = _conn;

                _cmd.CommandText = @"SELECT [Products].[GetProductValidStorage](@Schema)";

                _cmd.Parameters.Add("@Schema", SqlDbType.VarChar, 15);
                _cmd.Parameters["@Schema"].Value = schema;

                _conn.Open();
                var _result = _cmd.ExecuteScalar();
                _conn.Close();

                if (_result == DBNull.Value)
                    _storage = 0;
                else
                    _storage = Convert.ToInt32(_result);

                return _storage;
            }
        }

        public bool AddOrder(Order item)
        {
            using (SqlConnection _conn
                = new SqlConnection(this._connectionString))
            {
                SqlCommand _cmd;

                _cmd = new SqlCommand();
                _cmd.Connection = _conn;

                _cmd.CommandText = @"[Orders].[AddOrder]";
                _cmd.CommandType = CommandType.StoredProcedure;

                _cmd.Parameters.Add("@MemberGUID", SqlDbType.UniqueIdentifier);
                _cmd.Parameters.Add("@Items", SqlDbType.Structured);
                _cmd.Parameters.Add("@IsSuccess", SqlDbType.Bit);

                _cmd.Parameters["@Items"].TypeName = "[Orders].[OrderDetails]";
                _cmd.Parameters["@IsSuccess"].Direction = ParameterDirection.Output;

                _cmd.Parameters["@MemberGUID"].Value = item.MemberGUID.Value;
                _cmd.Parameters["@Items"].Value = this.MapToOrderItem(item.OrderItems);
                _cmd.Parameters["@IsSuccess"].Value = item.IsSuccess;

                _conn.Open();
                var _result = _cmd.ExecuteNonQuery();
                _conn.Close();

                item.IsSuccess = Convert.ToBoolean(_cmd.Parameters["@IsSuccess"].Value);

                return item.IsSuccess;
            }
        }

        private DataTable MapToOrderItem(IEnumerable<OrderItem> items)
        {
            DataTable _table;
            DataRow _row;

            _table = new DataTable();
            _table.Columns.Add("ProductNo", typeof(int));
            _table.Columns.Add("SellPrice", typeof(decimal));
            _table.Columns.Add("Quantity", typeof(int));

            foreach (var item in items)
            {
                _row = _table.NewRow();
                _row["ProductNo"] = item.ProductNo;
                _row["SellPrice"] = item.SellPrice;
                _row["Quantity"] = item.Quantity;
                _table.Rows.Add(_row);
            }

            return _table;
        }

    }
}

using System;
using System.Collections.Generic;
using System.Text;

namespace eShop.DbLoader
{
    public sealed class Order
    {
        public Guid? MemberGUID { get; set; }
        public IEnumerable<OrderItem> OrderItems { get; set; }
        public bool IsSuccess { get; set; }
    }

    public sealed class OrderItem
    {
        public int ProductNo { get; set; }
        public decimal SellPrice { get; set; }
        public int Quantity { get; set; }
    }
}

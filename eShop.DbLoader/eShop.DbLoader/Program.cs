using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Threading;
using System.Threading.Tasks;

namespace eShop.DbLoader
{
    class Program
    {
        /// <summary>指定要建立的 Task 數量</summary>
        static int taskNumber = 50;

        /// <summary>系統分鐘數超過此數值時開始執行所有建立的 Task 內容</summary>
        static int executeMinute = 4;

        //dotnet eShop.DbLoader.dll -task 100 -minute 55
        static void Main(string[] args)
        {
            List<Task> _tasks;

            _tasks = new List<Task>();

            SetArgs(args);


            eShopRepository _eShopRepository;

            _eShopRepository = new eShopRepository();
            _eShopRepository.ResetOrderTable();


            for (int i = 0; i < taskNumber; i++)
                _tasks.Add(new Task(AddOrder));

            for (int i = 0; i < _tasks.Count; i++)
                _tasks[i].Start();
            
            Console.ReadKey();
        }

        static void SetArgs(string[] args)
        {
            var _arg = string.Empty;
            var _index = 0;

            for (int i = 0; i < args.Length; i++)
            {
                _arg = args[i];
                _index = i + 1;

                if(_index <= args.Length)
                {
                    switch (_arg)
                    {
                        case "-task":
                            taskNumber = Convert.ToInt32(args[_index]);
                            break;
                        case "-minute":
                            executeMinute = Convert.ToInt32(args[_index]);
                            break;
                        default:
                            break;
                    }
                }
            }
        }

        static void AddOrder()
        {
            string _productSchema;
            int _storage;
            int _quantity;
            bool _execute;

            Guid _guid;
            Random _random;

            Order _order;
            List<OrderItem> _orderItems;
            eShopRepository _eShopRepository;

            _productSchema = "DYAJ93A900929IK";

            _execute = false;
            _guid = Guid.NewGuid();
            _random = new Random();
            _eShopRepository = new eShopRepository();

            Stopwatch _stopwatch = new Stopwatch();

            while (true)
            {
                int _currentMinute;

                _currentMinute = DateTime.Now.Minute;

                //直到達到指定分鐘後開始執行 - 這段程式碼不嚴謹
                if (executeMinute < _currentMinute)
                {
                    if (_execute == false)
                        Console.WriteLine("{0} start", _guid);

                    _execute = true;
                    _stopwatch.Start();
                }

                if (_execute == false)
                {
                    Thread.Sleep(100);
                    continue;
                }

                _storage = _eShopRepository.GetStorageBySchema(_productSchema);

                //有庫存的話進行新增訂單作業
                if (_storage > 0)
                {
                    _quantity = _random.Next(1, 3);

                    _orderItems = new List<OrderItem>();
                    _orderItems.Add(new OrderItem() { ProductNo = 1, Quantity = _quantity, SellPrice = 20000 });

                    _order = new Order();
                    _order.MemberGUID = _guid;
                    _order.OrderItems = _orderItems;

                    _eShopRepository.AddOrder(_order);
                }
                else
                {
                    //商品已無庫存，離開 while
                    _stopwatch.Stop();

                    Console.WriteLine("{0} finish\t{1} ms"
                                    , _guid
                                    , _stopwatch.ElapsedMilliseconds);
                    break;
                }
            }
        }
    }
}

// Program.cs
using System;
using System.Threading.Tasks;

class Program
{
    static async Task Main(string[] args)
    {
        // Lắng nghe trên tất cả các địa chỉ IP của máy và cổng 8888
        // Đây là cách cấu hình phổ biến khi triển khai trên VPS
        Server server = new Server("0.0.0.0", 8888);
        await server.StartAsync();
    }
}
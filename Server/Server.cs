// Server.cs
using System;
using System.Net;
using System.Net.Sockets;
using System.Threading.Tasks;

public class Server
{
    private TcpListener _listener;
    private bool _isRunning;

    public Server(string ipAddress, int port)
    {
        _listener = new TcpListener(IPAddress.Parse(ipAddress), port);
    }

    public async Task StartAsync()
    {
        _listener.Start();
        _isRunning = true;
        Console.WriteLine($"Server started. Listening on {_listener.LocalEndpoint}...");

        while (_isRunning)
        {
            try
            {
                // Chấp nhận kết nối từ client một cách bất đồng bộ
                TcpClient client = await _listener.AcceptTcpClientAsync();

                // Tạo một đối tượng ClientHandler mới để xử lý client này
                // Task.Run để đảm bảo vòng lặp chấp nhận kết nối không bị block
                ClientHandler clientHandler = new ClientHandler(client);
                _ = Task.Run(clientHandler.HandleClientAsync);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error accepting client: {ex.Message}");
            }
        }
    }

    public void Stop()
    {
        _isRunning = false;
        _listener.Stop();
    }
}
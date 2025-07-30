// ClientHandler.cs
using System;
using System.Net.Sockets;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;

public class ClientHandler
{
    private TcpClient _client;
    private NetworkStream _stream;
    public string? PlayerName { get; set; }
    public GameRoom? CurrentRoom { get; set; }
    public bool IsConnected { get; set; } = true;
    public Player? PlayerData { get; set; }

    public ClientHandler(TcpClient client)
    {
        _client = client;
        _stream = _client.GetStream();
    }

    public async Task HandleClientAsync()
    {
        Console.WriteLine($"Client connected: {_client.Client.RemoteEndPoint}");
        try
        {
            byte[] buffer = new byte[4096];
            int bytesRead;

            while ((bytesRead = await _stream.ReadAsync(buffer, 0, buffer.Length)) > 0)
            {
                string jsonString = Encoding.UTF8.GetString(buffer, 0, bytesRead);
                Console.WriteLine($"Received: {jsonString}");

                // 1. Deserialize để lấy Type
                var baseMessage = JsonSerializer.Deserialize<BaseMessage>(jsonString);

                // 2. Dùng switch-case để xử lý theo Type
                switch (baseMessage?.Type)
                {
                    case "CREATE_ROOM":
                        // Bạn sẽ hiện thực logic này ở Bước 3
                        HandleCreateRoom(jsonString);
                        break;

                    case "JOIN_ROOM":
                        // Dùng await vì HandleJoinRoom giờ là async
                        await HandleJoinRoom(jsonString);
                        break;

                    case "MAKE_MOVE":
                        HandleMakeMove(jsonString);
                        break;
                    case "RECONNECT":
                        await HandleReconnect(jsonString);
                        break;

                    default:
                        Console.WriteLine($"Unknown message type: {baseMessage?.Type}");
                        break;
                }
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error handling client: {ex.Message}");
        }
        finally
        {
            // Thông báo cho phòng game về việc ngắt kết nối
     // Kiểm tra xem client này có đang trong một ván game không
    if (this.PlayerData != null && this.CurrentRoom != null && this.CurrentRoom.State == RoomState.Playing)
    {
        // Truyền đối tượng Player vào phương thức
        await this.CurrentRoom.HandlePlayerDisconnection(this.PlayerData);
    }

            Console.WriteLine($"Client disconnected: {_client.Client.RemoteEndPoint}");
            _client.Close();
        }
    }
    public async Task SendMessageAsync(BaseMessage message)
    {
        try
        {
            string jsonResponse = JsonSerializer.Serialize(message, message.GetType());
            byte[] buffer = Encoding.UTF8.GetBytes(jsonResponse);
            await _stream.WriteAsync(buffer, 0, buffer.Length);
            Console.WriteLine($"Sent to {_client.Client.RemoteEndPoint}: {jsonResponse}");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error sending message: {ex.Message}");
        }
    }
    private void HandleCreateRoom(string jsonString)
    {
        var request = JsonSerializer.Deserialize<CreateRoomRequest>(jsonString);
        if (request == null) return;

        // 1. Tạo đối tượng Player
        var newPlayer = new Player(request.PlayerName, this);
        this.PlayerData = newPlayer; // Gán PlayerData cho ClientHandler này

        // 2. Gọi LobbyManager để tạo phòng
        var room = LobbyManager.CreateRoom();
        this.CurrentRoom = room;

        // 3. Thêm Player vào phòng
        room.AddPlayer(newPlayer);

        // 4. Gửi phản hồi
        var response = new RoomCreatedResponse
        {
            Type = "ROOM_CREATED",
            RoomId = room.RoomId,
            // Quan trọng: Gửi SessionToken về cho client ngay khi tạo phòng
            SessionToken = newPlayer.SessionToken
        };
        _ = SendMessageAsync(response);
    }
   private async Task HandleJoinRoom(string jsonString)
{
    var request = JsonSerializer.Deserialize<JoinRoomRequest>(jsonString);
    if (request == null) return;

    var room = LobbyManager.GetRoom(request.RoomId.ToUpper());

    // ... phần kiểm tra phòng không tồn tại, phòng đầy/đang chơi giữ nguyên ...

    // 3. Xử lý khi vào phòng thành công
    this.CurrentRoom = room;
    var newPlayer = new Player(request.PlayerName, this);
    this.PlayerData = newPlayer;

    // Thông báo cho người chơi cũ về người mới
    var notification = new PlayerJoinedNotification { /*...*/ };
    await room.BroadcastMessageAsync(notification);

    // Lấy danh sách người chơi HIỆN TẠI (trước khi thêm người mới)
    var existingPlayers = room.Players.Select((p, index) => new PlayerInfo { PlayerName = p.PlayerName, PlayerId = index }).ToList();

    // Thêm người chơi mới vào phòng
    room.AddPlayer(newPlayer);

    // Gửi kết quả thành công cho người chơi mới
    var joinResult = new JoinRoomResult
    {
        Type = "JOIN_RESULT",
        Success = true,
        RoomId = room.RoomId,
        Players = existingPlayers, // Gửi danh sách người chơi cũ
        SessionToken = newPlayer.SessionToken
    };
    await SendMessageAsync(joinResult);
}
    private void HandleMakeMove(string jsonString)
    {
        var request = JsonSerializer.Deserialize<MakeMoveRequest>(jsonString);
        if (request == null || this.CurrentRoom == null) return;

        // Chuyển việc xử lý logic cho GameRoom
        this.CurrentRoom.ProcessPlayerMove(this.PlayerData, request.X, request.Y);
    }
    private async Task HandleReconnect(string jsonString)
    {
        var request = JsonSerializer.Deserialize<ReconnectRequest>(jsonString);
        if (request == null) return;

        var room = LobbyManager.GetRoom(request.RoomId);
        if (room == null) return; // Phòng không tồn tại

        // Tìm người chơi trong phòng bằng token
        var playerToReconnect = room.Players.FirstOrDefault(p => p.SessionToken == request.SessionToken);

        if (playerToReconnect != null && !playerToReconnect.IsConnected)
        {
            Console.WriteLine($"Player {playerToReconnect.PlayerName} has reconnected!");

            // Gán lại kết nối mới cho đối tượng Player cũ
            playerToReconnect.ActiveConnection = this;
            this.PlayerData = playerToReconnect;
            this.CurrentRoom = room;

            // Gửi thông báo kết nối lại thành công cho client
            // Gửi thông báo cho những người khác rằng người chơi đã online trở lại
            // ... (Bạn có thể tự thêm các model và logic này)
        }
    }
}


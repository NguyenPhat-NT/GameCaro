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
    var buffer = new byte[4096];
    var messageBuffer = new StringBuilder(); // Dùng StringBuilder để xây dựng chuỗi JSON hoàn chỉnh

    try
    {
        while (true)
        {
            int bytesRead = await _stream.ReadAsync(buffer, 0, buffer.Length);
            if (bytesRead == 0)
            {
                // Client đã đóng kết nối
                break;
            }

            // Nối dữ liệu mới đọc được vào bộ đệm
            messageBuffer.Append(Encoding.UTF8.GetString(buffer, 0, bytesRead));

            // Xử lý tất cả các tin nhắn JSON hoàn chỉnh có trong bộ đệm
            ProcessBuffer(messageBuffer);
        }
    }
        catch (Exception ex)
        {
            Console.WriteLine($"Error handling client {PlayerData?.PlayerName}: {ex.Message}");
        }
        finally
        {
            // Đánh dấu kết nối đã ngắt
            if (PlayerData != null)
            {
                PlayerData.ActiveConnection = null;
            }

            // Xử lý logic ngắt kết nối cho cả 2 trường hợp: Đang chờ hoặc Đang chơi
            if (this.PlayerData != null && !this.PlayerData.HasLeft && this.CurrentRoom != null)
            {
                Console.WriteLine($"Handling disconnection for player {PlayerData.PlayerName} in room {CurrentRoom.RoomId} (State: {CurrentRoom.State})...");

                if (this.CurrentRoom.State == RoomState.Playing)
                {
                    // Nếu đang chơi, bắt đầu đếm giờ 30s
                    await this.CurrentRoom.HandlePlayerDisconnection(this.PlayerData);
                }
                else if (this.CurrentRoom.State == RoomState.Waiting)
                {
                    // Nếu đang ở phòng chờ, xử lý như người chơi chủ động thoát
                    await this.CurrentRoom.HandlePlayerLeaving(this.PlayerData);
                }
            }

            Console.WriteLine($"Client disconnected: {PlayerData?.PlayerName ?? "Unknown"} at {_client.Client.RemoteEndPoint}");
            _client.Close();
        }
    }
    private void ProcessBuffer(StringBuilder messageBuffer)
{
    while (true)
    {
        string currentBuffer = messageBuffer.ToString();
        if (string.IsNullOrWhiteSpace(currentBuffer))
            break;

        // Tìm vị trí kết thúc của một JSON object hoàn chỉnh đầu tiên
        int jsonEndIndex = FindJsonEnd(currentBuffer);

        if (jsonEndIndex != -1)
        {
            // Trích xuất tin nhắn JSON hoàn chỉnh
            string jsonMessage = currentBuffer.Substring(0, jsonEndIndex);
            
            // Xóa tin nhắn vừa xử lý khỏi bộ đệm
            messageBuffer.Remove(0, jsonEndIndex);

            // Xử lý tin nhắn JSON
            try
            {
                Console.WriteLine($"Processing JSON: {jsonMessage}");
                var baseMessage = JsonSerializer.Deserialize<BaseMessage>(jsonMessage);
                
                // Dùng Task.Run để không block vòng lặp xử lý buffer
                _ = Task.Run(() => DispatchMessage(baseMessage, jsonMessage));
            }
            catch (JsonException ex)
            {
                Console.WriteLine($"JSON Deserialization Error: {ex.Message}. Corrupted data: {jsonMessage}");
            }
        }
        else
        {
            // Không tìm thấy JSON hoàn chỉnh, đợi thêm dữ liệu
            break;
        }
    }
}

// Phương thức điều phối tin nhắn (tách ra từ switch-case cũ)
private async Task DispatchMessage(BaseMessage? baseMessage, string jsonString)
{
    switch (baseMessage?.Type)
    {
        case "CREATE_ROOM": HandleCreateRoom(jsonString); break;
        case "JOIN_ROOM": await HandleJoinRoom(jsonString); break;
        case "LEAVE_ROOM": await HandleLeaveRoom(); break;
        case "SURRENDER": await HandleSurrender(); break;
        case "START_GAME_EARLY": HandleStartGameEarly(); break;
        case "FIND_MATCH": await HandleFindMatch(jsonString); break;
        case "GET_ROOM_LIST": await HandleGetRoomList(); break;
        case "CONFIRM_READINESS": HandleConfirmReadiness(); break;
        case "MAKE_MOVE": await HandleMakeMove(jsonString); break;
        case "SEND_CHAT_MESSAGE": HandleSendChatMessage(jsonString); break;
        case "RECONNECT": await HandleReconnect(jsonString); break;
        default: Console.WriteLine($"Unknown message type: {baseMessage?.Type}"); break;
    }
}


// Phương thức hỗ trợ tìm điểm kết thúc của JSON
private int FindJsonEnd(string buffer)
{
    int braceCount = 0;
    bool inString = false;
    for (int i = 0; i < buffer.Length; i++)
    {
        char c = buffer[i];
        if (c == '"' && (i == 0 || buffer[i - 1] != '\\'))
        {
            inString = !inString;
        }

        if (!inString)
        {
            if (c == '{') braceCount++;
            else if (c == '}') braceCount--;
        }

        if (braceCount == 0 && i > 0)
        {
            // Tìm thấy một JSON object hoàn chỉnh
            return i + 1;
        }
    }
    return -1; // Không tìm thấy
}


    public async Task SendMessageAsync(BaseMessage message)
    {
        try
        {
            if (_client.Connected)
            {
                string jsonResponse = JsonSerializer.Serialize(message, message.GetType());
                byte[] buffer = Encoding.UTF8.GetBytes(jsonResponse);
                await _stream.WriteAsync(buffer, 0, buffer.Length);
                Console.WriteLine($"Sent to {PlayerData?.PlayerName}: {jsonResponse}");
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error sending message to {PlayerData?.PlayerName}: {ex.Message}");
        }
    }

    // ================================================================
    // THÊM PHƯƠNG THỨC MỚI ĐỂ XỬ LÝ TIN NHẮN CHAT
    // ================================================================
    private void HandleSendChatMessage(string jsonString)
    {
        if (this.CurrentRoom == null || this.PlayerData == null)
        {
            Console.WriteLine("Warning: Client tried to chat without being in a room.");
            return;
        }

        var message = JsonSerializer.Deserialize<ClientMessage<SendChatMessagePayload>>(jsonString);
        var payload = message?.Payload;
        if (string.IsNullOrWhiteSpace(payload?.Message))
        {
            return; // Bỏ qua tin nhắn rỗng hoặc chỉ có khoảng trắng
        }

        // Ủy quyền việc xử lý cho GameRoom mà không cần đợi
        _ = this.CurrentRoom.BroadcastChatMessageAsync(this.PlayerData, payload.Message);
    }
    // ================================================================

    private void HandleCreateRoom(string jsonString)
    {
        var message = JsonSerializer.Deserialize<ClientMessage<CreateRoomRequest>>(jsonString);
        var payload = message?.Payload;
        if (payload == null || payload.PlayerName == null) return;

        var newPlayer = new Player(payload.PlayerName, this);
        this.PlayerData = newPlayer;

        var room = LobbyManager.CreateRoom();
        this.CurrentRoom = room;

        room.AddPlayer(newPlayer);

        var response = new RoomCreatedResponse
        {
            Type = "ROOM_CREATED",
            Payload = new RoomCreatedPayload
            {
                RoomId = room.RoomId,
                SessionToken = newPlayer.SessionToken
            }
        };
        _ = SendMessageAsync(response);
    }

    private async Task HandleJoinRoom(string jsonString)
    {
        if (string.IsNullOrEmpty(jsonString)) return;
        var message = JsonSerializer.Deserialize<ClientMessage<JoinRoomRequest>>(jsonString);
        var payload = message?.Payload;
        if (payload?.RoomId == null || payload.PlayerName == null) return;

        var room = LobbyManager.GetRoom(payload.RoomId);
        if (room == null)
        {
            // TODO: Gửi tin nhắn lỗi về cho client
            return;
        }

        this.CurrentRoom = room;
        var newPlayer = new Player(payload.PlayerName, this);
        this.PlayerData = newPlayer;

        var notification = new PlayerJoinedNotification
        {
            Type = "PLAYER_JOINED",
            Payload = new PlayerJoinedPayload
            {
                PlayerName = newPlayer.PlayerName,
                PlayerId = room.Players.Count // ID sẽ là vị trí tiếp theo trong danh sách
            }
        };

        // Gửi thông báo cho những người chơi cũ trước khi thêm người mới vào danh sách
        await room.BroadcastMessageAsync(notification);

        // Lấy danh sách người chơi hiện tại để gửi cho người mới
        var existingPlayers = room.Players.Select((p, index) => new PlayerInfo { PlayerName = p.PlayerName, PlayerId = index, SessionToken = p.SessionToken, IsHost = p.IsHost }).ToList();

        // Thêm người chơi mới vào phòng
        room.AddPlayer(newPlayer);

        // Gửi kết quả tham gia thành công cho người chơi mới
        var joinResult = new JoinRoomResult
        {
            Type = "JOIN_RESULT",
            Payload = new JoinResultPayload
            {
                Success = true,
                RoomId = room.RoomId,
                Players = existingPlayers,
                SessionToken = newPlayer.SessionToken
            }
        };
        await SendMessageAsync(joinResult);

        if (room.Players.Count == 4)
        {
            _ = Task.Run(() => room.StartGame());
        }
    }

    private async Task HandleMakeMove(string jsonString)
    {
        if (string.IsNullOrEmpty(jsonString)) return;
        var message = JsonSerializer.Deserialize<ClientMessage<MakeMoveRequest>>(jsonString);
        var payload = message?.Payload;
        if (payload == null || this.CurrentRoom == null || this.PlayerData == null) return;

        await this.CurrentRoom.ProcessPlayerMoveAsync(this.PlayerData, payload.X, payload.Y);
    }

    private async Task HandleReconnect(string jsonString)
    {
        // Cũ: var request = JsonSerializer.Deserialize<ClientMessage<ReconnectRequest>>(jsonString)?.Payload;
        var request = JsonSerializer.Deserialize<ClientMessage<ReconnectRequest>>(jsonString)?.Payload; // Đã sửa
        if (request?.RoomId == null || request.SessionToken == null) return;

        var room = LobbyManager.GetRoom(request.RoomId);
        Player? playerToReconnect = room?.Players.FirstOrDefault(p => p.SessionToken == request.SessionToken);

        // Xử lý trường hợp thất bại (phòng không tồn tại, token sai, hoặc người chơi đang online)
        if (room == null || playerToReconnect == null || playerToReconnect.IsConnected)
        {
            var failureResponse = new ReconnectResultResponse
            {
                Type = "RECONNECT_RESULT",
                Payload = new ReconnectResultPayload { Success = false, GameState = null }
            };
            await SendMessageAsync(failureResponse);
            Console.WriteLine($"Reconnect failed for token {request.SessionToken} in room {request.RoomId}.");
            return;
        }

        // Xử lý trường hợp thành công
        // 1. Gán lại kết nối mới
        playerToReconnect.ActiveConnection = this;
        this.PlayerData = playerToReconnect;
        this.CurrentRoom = room;
        Console.WriteLine($"Player {playerToReconnect.PlayerName} reconnected successfully.");

        // 2. Gửi RECONNECT_RESULT với toàn bộ trạng thái game
        var gameState = new GameStatePayload
        {
            Players = room.Players.Select((p, index) => new PlayerInfo
            {
                PlayerName = p.PlayerName,
                PlayerId = p.RoomPlayerId, // <-- Bắt đầu sử dụng RoomPlayerId ở đây
                SessionToken = p.SessionToken,
                IsHost = p.IsHost
            }).ToList(),
            Moves = room.MoveHistory,
            CurrentPlayerId = room.Players[room.CurrentPlayerIndex].RoomPlayerId, // <-- Gửi ID cố định
            ChatHistory = room.ChatHistory
        };

        var successResponse = new ReconnectResultResponse
        {
            Type = "RECONNECT_RESULT",
            Payload = new ReconnectResultPayload { Success = true, GameState = gameState }
        };
        await SendMessageAsync(successResponse);

        // 3. Gửi thông báo PLAYER_RECONNECTED cho những người khác
        var notification = new PlayerReconnectedNotification
        {
            Type = "PLAYER_RECONNECTED",
            PlayerId = playerToReconnect.RoomPlayerId // <-- Gửi ID cố định
        };
        await room.BroadcastMessageAsync(notification, excludePlayer: playerToReconnect);
    }
    private async Task HandleLeaveRoom()
    {
        if (this.CurrentRoom == null || this.PlayerData == null)
        {
            // Người chơi này không ở trong phòng nào, bỏ qua.
            return;
        }

        // 1. Gọi vào GameRoom để xử lý logic chính (thông báo cho người khác, chuyển lượt,...)
        await this.CurrentRoom.HandlePlayerLeaving(this.PlayerData);

        // 2. Gửi xác nhận cho chính client vừa yêu cầu thoát
        await SendMessageAsync(new LeaveRoomSuccessResponse());

        // 3. Dọn dẹp trạng thái của ClientHandler này
        this.CurrentRoom = null;
    }
    private async Task HandleSurrender()
    {
        if (this.CurrentRoom == null || this.PlayerData == null)
        {
            return; // Người chơi không ở trong phòng nào
        }

        // Ủy quyền toàn bộ logic cho GameRoom
        await this.CurrentRoom.HandleSurrender(this.PlayerData);
    }
    private void HandleStartGameEarly()
    {
        if (this.CurrentRoom == null || this.PlayerData == null) return;

        // Ủy quyền cho GameRoom
        this.CurrentRoom.StartGameEarly(this.PlayerData);
    }
    private async Task HandleFindMatch(string jsonString)
    {
        var message = JsonSerializer.Deserialize<ClientMessage<FindMatchPayload>>(jsonString);
        var payload = message?.Payload;
        if (string.IsNullOrEmpty(payload?.PlayerName)) return;

        // 1. Tạo đối tượng Player
        var newPlayer = new Player(payload.PlayerName, this);
        this.PlayerData = newPlayer;

        // 2. Gọi LobbyManager để tìm hoặc tạo phòng
        var room = LobbyManager.FindOrCreateRoomForPlayer(newPlayer);
        this.CurrentRoom = room;

        // 3. Tái sử dụng logic Join Room:
        //    - Gửi thông báo cho người cũ
        //    - Gửi kết quả cho người mới
        //    - Thêm người mới vào phòng

        // Gửi thông báo cho những người chơi cũ về người mới vào
        var notification = new PlayerJoinedNotification
        {
            Type = "PLAYER_JOINED",
            Payload = new PlayerJoinedPayload
            {
                PlayerName = newPlayer.PlayerName,
                PlayerId = room.Players.Count
            }
        };
        await room.BroadcastMessageAsync(notification);

        // Chuẩn bị và gửi kết quả cho người chơi mới
        var existingPlayers = room.Players.Select((p, index) => new PlayerInfo
        {
            PlayerName = p.PlayerName,
            PlayerId = index,
            SessionToken = p.SessionToken,
            IsHost = p.IsHost
        }).ToList();

        var joinResult = new JoinRoomResult
        {
            Type = "JOIN_RESULT",
            Payload = new JoinResultPayload
            {
                Success = true,
                RoomId = room.RoomId,
                Players = existingPlayers,
                SessionToken = newPlayer.SessionToken
            }
        };
        await SendMessageAsync(joinResult);

        // Thêm người chơi mới vào phòng
        room.AddPlayer(newPlayer);

        // Kiểm tra và bắt đầu game nếu đủ người
        if (room.Players.Count == 4)
        {
            _ = Task.Run(() => room.StartGame());
        }
    }
    private async Task HandleGetRoomList()
    {
        // 1. Gọi LobbyManager để lấy danh sách phòng
        var rooms = LobbyManager.GetAvailableRooms();

        // 2. Tạo gói tin phản hồi
        var response = new RoomListUpdateResponse
        {
            Type = "ROOM_LIST_UPDATE",
            Payload = new RoomListUpdatePayload
            {
                Rooms = rooms
            }
        };

        // 3. Gửi danh sách về cho client đã yêu cầu
        await SendMessageAsync(response);
    }
    private void HandleConfirmReadiness()
{
    if (this.PlayerData != null)
    {
        this.PlayerData.HasConfirmedReadiness = true;
        Console.WriteLine($"[AFK Check] Player {this.PlayerData.PlayerName} confirmed readiness.");
    }
}
}
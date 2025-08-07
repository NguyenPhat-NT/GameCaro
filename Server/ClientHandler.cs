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
                Console.WriteLine($"Received from {PlayerData?.PlayerName ?? "New Client"}: {jsonString}");

                var baseMessage = JsonSerializer.Deserialize<BaseMessage>(jsonString);

                switch (baseMessage?.Type)
                {
                    case "CREATE_ROOM":
                        HandleCreateRoom(jsonString);
                        break;

                    case "JOIN_ROOM":
                        await HandleJoinRoom(jsonString);
                        break;
                    case "LEAVE_ROOM":
                        await HandleLeaveRoom();
                        break;
                    case "START_GAME_EARLY":
                        HandleStartGameEarly();
                        break;

                    case "MAKE_MOVE":
                        HandleMakeMove(jsonString);
                        break;
                    case "SURRENDER":
                        await HandleSurrender();
                        break;

                    // ================================================================
                    // THÊM CASE MỚI ĐỂ XỬ LÝ TIN NHẮN CHAT
                    // ================================================================
                    case "SEND_CHAT_MESSAGE":
                        HandleSendChatMessage(jsonString);
                        break;
                    // ================================================================

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
            Console.WriteLine($"Error handling client {PlayerData?.PlayerName}: {ex.Message}");
        }
        finally
        {
            IsConnected = false;
            // Chỉ xử lý ngắt kết nối khi đang chơi và người chơi chưa chủ động thoát
            if (this.PlayerData != null && !this.PlayerData.HasLeft && this.CurrentRoom != null && this.CurrentRoom.State == RoomState.Playing)
            {
                await this.CurrentRoom.HandlePlayerDisconnection(this.PlayerData);
            }

            Console.WriteLine($"Client disconnected: {PlayerData?.PlayerName ?? "Unknown"} at {_client.Client.RemoteEndPoint}");
            _client.Close();
        }
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
        var existingPlayers = room.Players.Select((p, index) => new PlayerInfo { PlayerName = p.PlayerName, PlayerId = index, SessionToken = p.SessionToken, IsHost = p.IsHost}).ToList();

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

    private async Task HandleReconnect(string? jsonString)
    {
        if (string.IsNullOrEmpty(jsonString)) return;
        var request = JsonSerializer.Deserialize<ClientMessage<ReconnectRequest>>(jsonString)?.Payload;
        if (request?.RoomId == null || request.SessionToken == null) return;

        var room = LobbyManager.GetRoom(request.RoomId);
        if (room == null) return;

        var playerToReconnect = room.Players.FirstOrDefault(p => p.SessionToken == request.SessionToken);
        if (playerToReconnect != null && !playerToReconnect.IsConnected)
        {
            playerToReconnect.ActiveConnection = this;
            this.PlayerData = playerToReconnect;
            this.CurrentRoom = room;

            // ================================================================
            // CẬP NHẬT TẠI ĐÂY
            // ================================================================
            var gameStateUpdate = new GameStateUpdateMessage
            {
                Type = "GAME_STATE_UPDATE",
                Players = room.Players.Select((p, index) => new PlayerInfo { PlayerName = p.PlayerName, PlayerId = index, SessionToken = p.SessionToken }).ToList(),
                Moves = room.MoveHistory,
                CurrentPlayerId = room.CurrentPlayerIndex,
                // Gửi kèm lịch sử chat đã được lưu
                ChatHistory = room.ChatHistory
            };
            // ================================================================

            await SendMessageAsync(gameStateUpdate);

            var notification = new PlayerReconnectedNotification
            {
                Type = "PLAYER_RECONNECTED",
                PlayerId = room.Players.IndexOf(playerToReconnect)
            };
            await room.BroadcastMessageAsync(notification, excludePlayer: playerToReconnect);
        }
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
}
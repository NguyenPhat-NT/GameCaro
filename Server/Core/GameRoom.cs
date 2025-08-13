// Core/GameRoom.cs
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json; // Cần thêm để sử dụng trong phương thức mới
using System.Threading.Tasks;

// Thêm enum này để quản lý trạng thái phòng
public enum RoomState
{
    Waiting,
    Playing,
    Finished
}

public class GameRoom
{
    public Player? Host { get; private set; }
    public string RoomId { get; }
    public List<Player> Players { get; } = new List<Player>();
    public List<MoveInfo> MoveHistory { get; } = new List<MoveInfo>();

    // THUỘC TÍNH MỚI: Dùng để lưu trữ toàn bộ tin nhắn trong phòng
    public List<ChatMessageReceivedPayload> ChatHistory { get; } = new List<ChatMessageReceivedPayload>();

    // Thuộc tính mới
    public RoomState State { get; private set; } = RoomState.Waiting;
    public int[,]? Board { get; private set; }
    public int CurrentPlayerIndex { get; private set; }
    public DateTime LastActivityTime { get; set; } = DateTime.UtcNow;
    public bool IsInReadinessCheck { get; set; } = false;
    private int _moveCount = 0;

    private const int BOARD_SIZE = 30;
    private int _nextPlayerIdCounter = 0;

    public GameRoom(string roomId)
    {
        RoomId = roomId;
    }

    public void AddPlayer(Player player)
    {
        if (State != RoomState.Waiting) return;

        // Gán ID cố định cho người chơi mới
        player.RoomPlayerId = _nextPlayerIdCounter;
        _nextPlayerIdCounter++;


        // Gán người đầu tiên làm chủ phòng
        if (Players.Count == 0)
        {
            player.IsHost = true;
            this.Host = player;
        }
        Players.Add(player);
        // Cập nhật thời gian hoạt động cuối cùng của phòng
        this.LastActivityTime = DateTime.UtcNow;
    }

    public async Task BroadcastMessageAsync(BaseMessage message, Player? excludePlayer = null)
    {
        var broadcastTasks = new List<Task>();
        // Lọc người nhận: phải đang kết nối và chưa rời phòng
        var recipients = Players.Where(p => p != excludePlayer && !p.HasLeft && p.IsConnected && p.ActiveConnection != null);

        foreach (var player in recipients)
        {
            // Thêm tác vụ gửi tin của mỗi người vào một danh sách
            if (player.ActiveConnection != null)
            {
                broadcastTasks.Add(player.ActiveConnection.SendMessageAsync(message));
            }
        }

        // Chờ cho tất cả các tác vụ gửi tin hoàn thành
        await Task.WhenAll(broadcastTasks);
    }

    // ================================================================
    // PHƯƠNG THỨC MỚI ĐỂ XỬ LÝ CHAT
    // ================================================================
    public async Task BroadcastChatMessageAsync(Player sender, string message)
    {
        // Bước 1: Xác định ID và tên của người gửi
        int senderId = this.Players.IndexOf(sender);
        if (senderId == -1)
        {
            Console.WriteLine($"Error: Player {sender.PlayerName} not found in room {this.RoomId}.");
            return;
        }

        // Bước 2: Tạo đối tượng payload cho tin nhắn chat
        var chatPayload = new ChatMessageReceivedPayload
        {
            PlayerId = sender.RoomPlayerId,
            PlayerName = sender.PlayerName,
            Message = message
        };

        // Bước 3: Lưu tin nhắn này vào lịch sử của phòng
        this.ChatHistory.Add(chatPayload);

        // Bước 4: Tạo gói tin notification hoàn chỉnh để gửi đi
        var notification = new ChatMessageReceivedNotification
        {
            Type = "CHAT_MESSAGE_RECEIVED",
            Payload = chatPayload // Sử dụng lại payload đã tạo
        };

        // Bước 5: Gửi tin nhắn đến TẤT CẢ người chơi trong phòng
        await BroadcastMessageAsync(notification);
        Console.WriteLine($"Room {RoomId}: Chat message from {sender.PlayerName} was stored and broadcasted.");
    }
    // ================================================================

    public void StartGame()
    {
        Console.WriteLine($"Game starting in room {RoomId}...");
        this.State = RoomState.Playing;

        // ... (phần còn lại của phương thức StartGame giữ nguyên)
        var random = new Random();
        var shuffledPlayers = Players.OrderBy(p => random.Next()).ToList();
        Players.Clear();
        Players.AddRange(shuffledPlayers);

        this.Board = new int[BOARD_SIZE, BOARD_SIZE];
        int startingPlayerRoomId = Players[0].RoomPlayerId;
        this.CurrentPlayerIndex = 0;

        var playerInfoList = Players
            .Select((player, index) => new PlayerInfo { PlayerName = player.PlayerName, PlayerId = player.RoomPlayerId, SessionToken = player.SessionToken, IsHost = player.IsHost })
            .ToList();

        var notification = new GameStartNotification
        {
            Type = "GAME_START",
            Payload = new GameStartPayload
            {
                BoardSize = BOARD_SIZE,
                Players = playerInfoList,
                StartingPlayerId = startingPlayerRoomId
            }
        };
        _ = BroadcastMessageAsync(notification);
    }

    public async Task ProcessPlayerMoveAsync(Player player, int x, int y)
    {
        if (this.Board == null) return;
        if (this.State != RoomState.Playing) return;
        if (this.Players[this.CurrentPlayerIndex] != player) return;
        if (x < 0 || x >= BOARD_SIZE || y < 0 || y >= BOARD_SIZE) return;
        if (this.Board[x, y] != 0) return;

        this.Board[x, y] = this.CurrentPlayerIndex + 1;
        _moveCount++;
        MoveHistory.Add(new MoveInfo { X = x, Y = y, PlayerId = this.CurrentPlayerIndex });

        var boardUpdateNotif = new BoardUpdateNotification
        {
            Type = "BOARD_UPDATE",
            Payload = new BoardUpdatePayload
            {
                X = x,
                Y = y,
                PlayerId = player.RoomPlayerId
            }
        };
        _ = BroadcastMessageAsync(boardUpdateNotif);

        // Thay đổi ở phần kiểm tra thắng/hòa
        if (CheckWinCondition(x, y))
        {
            var winner = Players[this.CurrentPlayerIndex];
            var payload = new GameOverPayload { WinnerId = winner.RoomPlayerId, IsDraw = false };
            await EndGameSequence(payload);
            return;
        }

        if (_moveCount >= BOARD_SIZE * BOARD_SIZE)
        {
            var payload = new GameOverPayload { IsDraw = true, WinnerId = -1 };
            await EndGameSequence(payload);
            return;
        }

        await AdvanceTurn();
    }

    private bool CheckWinCondition(int lastX, int lastY)
    {
        if (this.Board == null) return false;
        int playerMark = this.Board[lastX, lastY];
        if (playerMark == 0) return false;

        // Ngang
        int count = 1;
        for (int i = 1; i < 5; i++) { if (lastY + i < BOARD_SIZE && this.Board[lastX, lastY + i] == playerMark) count++; else break; }
        for (int i = 1; i < 5; i++) { if (lastY - i >= 0 && this.Board[lastX, lastY - i] == playerMark) count++; else break; }
        if (count >= 5) return true;

        // Dọc
        count = 1;
        for (int i = 1; i < 5; i++) { if (lastX + i < BOARD_SIZE && this.Board[lastX + i, lastY] == playerMark) count++; else break; }
        for (int i = 1; i < 5; i++) { if (lastX - i >= 0 && this.Board[lastX - i, lastY] == playerMark) count++; else break; }
        if (count >= 5) return true;

        // Chéo chính
        count = 1;
        for (int i = 1; i < 5; i++) { if (lastX + i < BOARD_SIZE && lastY + i < BOARD_SIZE && this.Board[lastX + i, lastY + i] == playerMark) count++; else break; }
        for (int i = 1; i < 5; i++) { if (lastX - i >= 0 && lastY - i >= 0 && this.Board[lastX - i, lastY - i] == playerMark) count++; else break; }
        if (count >= 5) return true;

        // Chéo phụ
        count = 1;
        for (int i = 1; i < 5; i++) { if (lastX + i < BOARD_SIZE && lastY - i >= 0 && this.Board[lastX + i, lastY - i] == playerMark) count++; else break; }
        for (int i = 1; i < 5; i++) { if (lastX - i >= 0 && lastY + i < BOARD_SIZE && this.Board[lastX - i, lastY + i] == playerMark) count++; else break; }
        if (count >= 5) return true;

        return false;
    }

    public async Task HandlePlayerDisconnection(Player disconnectedPlayer)
    {
        int disconnectedPlayerId = Players.IndexOf(disconnectedPlayer);
        Console.WriteLine($"Player {disconnectedPlayer.PlayerName} disconnected. Starting 30s timer...");

        var notification = new PlayerDisconnectedNotification
        {
            Type = "PLAYER_DISCONNECTED",
            PlayerId = disconnectedPlayer.RoomPlayerId,
            ReconnectTime = 30
        };
        await BroadcastMessageAsync(notification, excludePlayer: disconnectedPlayer);

        await Task.Delay(30000);

        // Sau 30 giây, kiểm tra lại
        if (disconnectedPlayer.ActiveConnection == null && !disconnectedPlayer.HasLeft)
        {
            Console.WriteLine($"Player {disconnectedPlayer.PlayerName} failed to reconnect. Marking as left.");

            // Đánh dấu người chơi đã rời đi
            disconnectedPlayer.HasLeft = true;

            // --- SỬA LỖI TẠI ĐÂY ---
            // Thay vì tự gửi GAME_OVER, ta gọi AdvanceTurn. 
            // AdvanceTurn sẽ tự phát hiện ra người thắng và gọi EndGameSequence.
            await AdvanceTurn();
        }
    }
    // ================================================================
    // PHƯƠNG THỨC MỚI: XỬ LÝ KHI NGƯỜI CHƠI THOÁT PHÒNG
    // ================================================================
    public async Task HandlePlayerLeaving(Player leavingPlayer)
    {
        int leavingPlayerId_Index = Players.IndexOf(leavingPlayer);
        if (leavingPlayerId_Index == -1) return;

        // Kịch bản 1: Người chơi thoát khi đang ở phòng chờ
        if (this.State == RoomState.Waiting)
        {
            // Trường hợp 1A: Người thoát là CHỦ PHÒNG -> Hủy phòng
            if (leavingPlayer.IsHost)
            {
                Console.WriteLine($"Host {leavingPlayer.PlayerName} has left waiting room {this.RoomId}. Closing the room.");

                // Tạo thông báo phòng bị đóng
                var notification = new RoomClosedNotification
                {
                    Type = "ROOM_CLOSED",
                    Payload = new RoomClosedPayload { Reason = "Host has left the room." }
                };

                // Gửi thông báo cho tất cả người chơi CÒN LẠI
                await BroadcastMessageAsync(notification, excludePlayer: leavingPlayer);

                // Xóa phòng này khỏi danh sách quản lý của server
                LobbyManager.RemoveRoom(this.RoomId);
            }
            // Trường hợp 1B: Người thoát là người chơi thường
            else
            {
                // Chỉ cần xóa họ khỏi danh sách
                Players.Remove(leavingPlayer);
                Console.WriteLine($"Player {leavingPlayer.PlayerName} removed from waiting room {this.RoomId}.");

                // Và thông báo cho những người còn lại
                var notification = new PlayerLeftNotification
                {
                    Type = "PLAYER_LEFT",
                    Payload = new PlayerLeftPayload
                    {
                        PlayerId = leavingPlayerId_Index,
                        PlayerName = leavingPlayer.PlayerName
                    }
                };
                await BroadcastMessageAsync(notification, excludePlayer: leavingPlayer);
            }
            // Cập nhật thời gian hoạt động cuối cùng của phòng
            this.LastActivityTime = DateTime.UtcNow;
        }
        // Kịch bản 2: Người chơi thoát khi trận đấu ĐANG DIỄN RA
        else if (this.State == RoomState.Playing)
        {
            // Đánh dấu người chơi đã thoát nhưng không xóa khỏi danh sách
            leavingPlayer.HasLeft = true;
            leavingPlayer.ActiveConnection = null;
            Console.WriteLine($"Player {leavingPlayer.PlayerName} has left ongoing match in room {this.RoomId}.");

            // Thông báo cho những người chơi còn lại
            var notification = new PlayerLeftNotification
            {
                Type = "PLAYER_LEFT",
                Payload = new PlayerLeftPayload
                {
                    PlayerId = leavingPlayer.RoomPlayerId,
                    PlayerName = leavingPlayer.PlayerName
                }
            };
            await BroadcastMessageAsync(notification, excludePlayer: leavingPlayer);

            // Kiểm tra xem có người thắng ngay lập tức không (chỉ còn 1 người)
            var activePlayers = Players.Where(p => !p.HasLeft && !p.IsSurrendered).ToList();
            if (activePlayers.Count == 1)
            {
                var winner = activePlayers.First();
                this.State = RoomState.Finished;
                var gameOverNotif = new GameOverNotification
                {
                    Type = "GAME_OVER",
                    Payload = new GameOverPayload { WinnerId = Players.IndexOf(winner), IsDraw = false }
                };
                await EndGameSequence(gameOverNotif.Payload);
                Console.WriteLine($"Game over. Winner by default is {winner.PlayerName}.");
                return; // Game đã kết thúc
            }

            // Nếu game vẫn tiếp tục và là lượt của người vừa thoát, chuyển lượt đi
            if (this.CurrentPlayerIndex == leavingPlayerId_Index)
            {
                Console.WriteLine($"It was the leaving player's turn. Advancing turn...");
                await AdvanceTurn();
            }
        }
    }
    private async Task AdvanceTurn()
    {
        var activePlayers = Players.Where(p => !p.HasLeft && !p.IsSurrendered).ToList();

        if (activePlayers.Count <= 1)
        {
            if (activePlayers.Count == 1) // Nếu còn đúng 1 người -> người đó thắng
            {
                var winner = activePlayers.First();
                var payload = new GameOverPayload { WinnerId = winner.RoomPlayerId, IsDraw = false };
                await EndGameSequence(payload);
            }
            // Nếu không còn ai, phòng sẽ tự reset hoặc đóng
            this.State = RoomState.Finished;
            ResetRoomForNewGame();
            return;
        }
        // Vòng lặp để tìm người chơi hợp lệ tiếp theo
        do
        {
            this.CurrentPlayerIndex = (this.CurrentPlayerIndex + 1) % this.Players.Count;
        } while (Players[this.CurrentPlayerIndex].HasLeft || Players[this.CurrentPlayerIndex].IsSurrendered);

        // Thông báo về lượt đi mới
        var nextPlayer = Players[this.CurrentPlayerIndex];
        var turnUpdateNotif = new TurnUpdateNotification
        {
            Type = "TURN_UPDATE",
            Payload = new TurnUpdatePayload
            {
                NextPlayerId = nextPlayer.RoomPlayerId
            }
        };
        await BroadcastMessageAsync(turnUpdateNotif);
    }
    public async Task HandleSurrender(Player surrenderingPlayer)
    {
        // 1. Kiểm tra điều kiện hợp lệ
        if (this.State != RoomState.Playing || surrenderingPlayer.IsSurrendered)
        {
            return; // Chỉ cho phép đầu hàng khi đang chơi và chưa đầu hàng
        }

        int surrenderingPlayerId = Players.IndexOf(surrenderingPlayer);
        if (surrenderingPlayerId == -1) return;

        // 2. Cập nhật trạng thái của người chơi
        surrenderingPlayer.IsSurrendered = true;
        Console.WriteLine($"Player {surrenderingPlayer.PlayerName} has surrendered in room {this.RoomId}.");

        // 3. Gửi thông báo cho tất cả mọi người trong phòng
        var notification = new PlayerSurrenderedNotification
        {
            Type = "PLAYER_SURRENDERED",
            Payload = new PlayerSurrenderedPayload { PlayerId = surrenderingPlayer.RoomPlayerId }
        };
        await BroadcastMessageAsync(notification);

        // 4. Kiểm tra xem có người chiến thắng ngay lập tức không (chỉ còn 1 người)
        // Thay đổi ở phần kiểm tra người thắng cuối cùng
        var activePlayers = Players.Where(p => !p.HasLeft && !p.IsSurrendered).ToList();
        if (activePlayers.Count == 1)
        {
            var winner = activePlayers.First();
            var payload = new GameOverPayload { WinnerId = winner.RoomPlayerId, IsDraw = false };
            await EndGameSequence(payload);
            return;
        }

        if (this.CurrentPlayerIndex == Players.IndexOf(surrenderingPlayer))
        {
            await AdvanceTurn();
        }
    }
    public void StartGameEarly(Player requestingPlayer)
    {
        // Chỉ chủ phòng mới có quyền bắt đầu sớm
        if (requestingPlayer != this.Host) return;
        // Chỉ có thể bắt đầu khi đang ở phòng chờ
        if (this.State != RoomState.Waiting) return;
        // Phải có ít nhất 2 người
        if (Players.Count < 2) return;

        // Gọi phương thức StartGame hiện có
        StartGame();
    }

    // ================================================================
    // PHƯƠNG THỨC HỖ TRỢ MỚI: RESET PHÒNG VỀ TRẠNG THÁI PHÒNG CHỜ
    // ================================================================
    private void ResetRoomForNewGame()
    {
        Console.WriteLine($"Resetting room {RoomId} for a new game.");

        // 1. Xóa các người chơi đã thoát giữa chừng
        Players.RemoveAll(p => p.HasLeft);

        // BƯỚC SỬA LỖI: Kiểm tra xem phòng có còn ai không SAU KHI xóa
        if (Players.Count == 0)
        {
            Console.WriteLine($"Room {RoomId} is empty after cleanup and will be removed.");
            LobbyManager.RemoveRoom(this.RoomId);
            return; // Dừng phương thức tại đây, không cần làm gì thêm
        }

        // 2. Reset trạng thái của những người chơi còn lại (nếu có)
        foreach (var player in Players)
        {
            player.IsSurrendered = false;
        }

        // 3. Gán lại chủ phòng nếu chủ phòng cũ đã thoát
        if (!Players.Contains(this.Host) && Players.Count > 0)
        {
            if (this.Host != null) this.Host.IsHost = false;

            this.Host = Players.First();
            this.Host.IsHost = true;
        }

        // 4. Reset các thuộc tính của ván đấu
        this.Board = new int[BOARD_SIZE, BOARD_SIZE];
        this.MoveHistory.Clear();
        this._moveCount = 0;
        this.State = RoomState.Waiting;
    }

    // ================================================================
    // PHƯƠNG THỨC HỖ TRỢ MỚI: LUỒNG XỬ LÝ KHI GAME KẾT THÚC
    // ================================================================
    private async Task EndGameSequence(GameOverPayload gameOverPayload)
    {
        // 1. Cập nhật trạng thái và gửi thông báo GAME_OVER
        this.State = RoomState.Finished;
        await BroadcastMessageAsync(new GameOverNotification { Type = "GAME_OVER", Payload = gameOverPayload });

        string reason = gameOverPayload.IsDraw ? "Draw" : $"Winner is Player {gameOverPayload.WinnerId}";
        Console.WriteLine($"Game over in room {RoomId}. Reason: {reason}.");

        // 2. Chờ 5 giây để người chơi xem kết quả
        await Task.Delay(5000);

        // 3. Reset lại phòng về trạng thái phòng chờ
        ResetRoomForNewGame();

         // Kiểm tra xem phòng có còn tồn tại không sau khi reset
    if (LobbyManager.GetRoom(this.RoomId) != null)
    {
        var playerInfoList = Players.Select(p => new PlayerInfo {
            PlayerName = p.PlayerName,
            PlayerId = p.RoomPlayerId,
            SessionToken = p.SessionToken,
            IsHost = p.IsHost
        }).ToList();

        var notification = new ReturnToLobbyNotification
        {
            Payload = new ReturnToLobbyPayload
            {
                Players = playerInfoList
            }
        };
        await BroadcastMessageAsync(notification);
    }
    }
    /// <summary>
/// Bắt đầu chu trình kiểm tra AFK cho phòng này.
/// </summary>
public async Task InitiateReadinessCheck()
{
    // 1. Đánh dấu phòng đang trong quá trình kiểm tra để tránh bị quét lại
    this.IsInReadinessCheck = true;

    // 2. Reset trạng thái xác nhận của tất cả người chơi trong phòng về false
    foreach (var p in Players)
    {
        p.HasConfirmedReadiness = false;
    }

    // 3. Gửi yêu cầu xác nhận tới tất cả client, báo họ có 60s để phản hồi
    var notification = new RequestReadinessCheckNotification
    {
        Type = "REQUEST_READINESS_CHECK",
        Payload = new RequestReadinessCheckPayload { Timeout = 60 }
    };
    await BroadcastMessageAsync(notification);

    // 4. Chờ 60 giây
    await Task.Delay(TimeSpan.FromSeconds(60));

    // 5. Sau khi hết giờ, gọi phương thức để kiểm tra kết quả
        FinalizeReadinessCheck();
}

/// <summary>
/// Kiểm tra kết quả sau khi hết 1 phút chờ.
/// </summary>
private void FinalizeReadinessCheck()
{
    // Tìm bất kỳ người chơi nào còn trong phòng MÀ VẪN CHƯA xác nhận
    var unreadyPlayer = Players.FirstOrDefault(p => !p.HasLeft && !p.HasConfirmedReadiness);

    if (unreadyPlayer != null) // Nếu có ít nhất 1 người không xác nhận
    {
        Console.WriteLine($"[AFK Check] Player {unreadyPlayer.PlayerName} in room {RoomId} failed to confirm. Closing room.");
        var notification = new RoomClosedNotification
        {
            Type = "ROOM_CLOSED",
            Payload = new RoomClosedPayload { Reason = "Phòng đã bị đóng do không có hoạt động." }
        };
        // Thông báo cho mọi người và xóa phòng
        _ = BroadcastMessageAsync(notification);
        LobbyManager.RemoveRoom(this.RoomId);
    }
    else // Nếu tất cả đều xác nhận (hoặc phòng đã trống)
    {
        Console.WriteLine($"[AFK Check] All players in room {RoomId} confirmed readiness.");
        // Reset lại cờ và cập nhật thời gian hoạt động để bộ đếm 5 phút bắt đầu lại
        this.IsInReadinessCheck = false;
        this.LastActivityTime = DateTime.UtcNow;
    }
}
}

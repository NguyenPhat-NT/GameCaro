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
    private int _moveCount = 0;

    private const int BOARD_SIZE = 30;

    public GameRoom(string roomId)
    {
        RoomId = roomId;
    }

    public void AddPlayer(Player player)
    {
        if (State != RoomState.Waiting) return;

        // Gán người đầu tiên làm chủ phòng
        if (Players.Count == 0)
        {
            player.IsHost = true;
            this.Host = player;
        }
        Players.Add(player);
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
            PlayerId = senderId,
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
        this.CurrentPlayerIndex = 0;

        var playerInfoList = Players
            .Select((player, index) => new PlayerInfo { PlayerName = player.PlayerName, PlayerId = index, SessionToken = player.SessionToken, IsHost = player.IsHost})
            .ToList();

        var notification = new GameStartNotification
        {
            Type = "GAME_START",
            Payload = new GameStartPayload
            {
                BoardSize = BOARD_SIZE,
                Players = playerInfoList,
                StartingPlayerId = this.CurrentPlayerIndex
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
                PlayerId = this.CurrentPlayerIndex
            }
        };
        _ = BroadcastMessageAsync(boardUpdateNotif);

        if (CheckWinCondition(x, y))
        {
            this.State = RoomState.Finished;
            var gameOverNotif = new GameOverNotification
            {
                Type = "GAME_OVER",
                Payload = new GameOverPayload
                {
                    WinnerId = this.CurrentPlayerIndex,
                    IsDraw = false
                }
            };
            _ = BroadcastMessageAsync(gameOverNotif);
            Console.WriteLine($"Game over in room {RoomId}. Winner is Player {this.CurrentPlayerIndex}");
            return;
        }

        if (_moveCount >= BOARD_SIZE * BOARD_SIZE)
        {
            this.State = RoomState.Finished;
            var gameOverNotif = new GameOverNotification
            {
                Type = "GAME_OVER",
                Payload = new GameOverPayload
                {
                    IsDraw = true,
                    WinnerId = -1
                }
            };
            _ = BroadcastMessageAsync(gameOverNotif);
            Console.WriteLine($"Game over in room {RoomId}. It's a draw.");
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
        disconnectedPlayer.ActiveConnection = null;
        int disconnectedPlayerId = Players.IndexOf(disconnectedPlayer);
        Console.WriteLine($"Player {disconnectedPlayer.PlayerName} disconnected. Starting 30s timer...");

        var notification = new PlayerDisconnectedNotification
        {
            Type = "PLAYER_DISCONNECTED",
            PlayerId = disconnectedPlayerId,
            ReconnectTime = 30
        };
        await BroadcastMessageAsync(notification, excludePlayer: disconnectedPlayer);

        await Task.Delay(30000);

        if (!disconnectedPlayer.IsConnected)
        {
            Console.WriteLine($"Player {disconnectedPlayer.PlayerName} failed to reconnect. Forfeited.");
            if (this.CurrentPlayerIndex == disconnectedPlayerId)
            {
                await AdvanceTurn();
            }
        }
    }
    // ================================================================
    // PHƯƠNG THỨC MỚI: XỬ LÝ KHI NGƯỜI CHƠI THOÁT PHÒNG
    // ================================================================
    public async Task HandlePlayerLeaving(Player leavingPlayer)
{
    int leavingPlayerId = Players.IndexOf(leavingPlayer);
    if (leavingPlayerId == -1) return;

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
                    PlayerId = leavingPlayerId,
                    PlayerName = leavingPlayer.PlayerName
                }
            };
            await BroadcastMessageAsync(notification, excludePlayer: leavingPlayer);
        }
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
                PlayerId = leavingPlayerId,
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
            await BroadcastMessageAsync(gameOverNotif);
            Console.WriteLine($"Game over. Winner by default is {winner.PlayerName}.");
            return; // Game đã kết thúc
        }

        // Nếu game vẫn tiếp tục và là lượt của người vừa thoát, chuyển lượt đi
        if (this.CurrentPlayerIndex == leavingPlayerId)
        {
            Console.WriteLine($"It was the leaving player's turn. Advancing turn...");
            await AdvanceTurn();
        }
    }
}
    private async Task AdvanceTurn()
    {
        // Kiểm tra xem còn ai có thể chơi không
        var activePlayers = Players.Where(p => !p.HasLeft && !p.IsSurrendered).ToList();
        if (activePlayers.Count == 1) // Nếu còn đúng 1 người -> người đó thắng
        {
            var winner = activePlayers.First();
            int winnerId = Players.IndexOf(winner);
            var gameOverNotif = new GameOverNotification
            {
                Type = "GAME_OVER",
                Payload = new GameOverPayload
                {
                    WinnerId = winnerId,
                    IsDraw = false
                }
            };
            await BroadcastMessageAsync(gameOverNotif);
            Console.WriteLine($"Game over. Winner by default is {winner.PlayerName}.");
        }

        // Vòng lặp để tìm người chơi hợp lệ tiếp theo
        do
        {
            this.CurrentPlayerIndex = (this.CurrentPlayerIndex + 1) % this.Players.Count;
        } while (Players[this.CurrentPlayerIndex].HasLeft || Players[this.CurrentPlayerIndex].IsSurrendered);

        // Thông báo về lượt đi mới
        var turnUpdateNotif = new TurnUpdateNotification
        {
            Type = "TURN_UPDATE",
            Payload = new TurnUpdatePayload
            {
                NextPlayerId = this.CurrentPlayerIndex
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
            Payload = new PlayerSurrenderedPayload { PlayerId = surrenderingPlayerId }
        };
        await BroadcastMessageAsync(notification);

        // 4. Kiểm tra xem có người chiến thắng ngay lập tức không (chỉ còn 1 người)
        var activePlayers = Players.Where(p => !p.HasLeft && !p.IsSurrendered).ToList();
        if (activePlayers.Count == 1)
        {
            var winner = activePlayers.First();
            int winnerId = Players.IndexOf(winner);
            this.State = RoomState.Finished;

            var gameOverNotif = new GameOverNotification
            {
                Type = "GAME_OVER",
                Payload = new GameOverPayload
                {
                    WinnerId = winnerId,
                    IsDraw = false
                }
            };
            await BroadcastMessageAsync(gameOverNotif);
            Console.WriteLine($"Game over. Winner by default is {winner.PlayerName}.");
            return;
        }

        // 5. Nếu game chưa kết thúc và là lượt của người vừa đầu hàng, chuyển lượt
        if (this.CurrentPlayerIndex == surrenderingPlayerId)
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
}
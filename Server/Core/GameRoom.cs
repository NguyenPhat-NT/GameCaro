// Core/GameRoom.cs
using System;
using System.Collections.Generic;
using System.Linq;
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
    public string RoomId { get; }
    public List<Player> Players { get; } = new List<Player>();
    public List<MoveInfo> MoveHistory { get; } = new List<MoveInfo>();

    // Thuộc tính mới
    public RoomState State { get; private set; } = RoomState.Waiting;
    public int[,]? Board { get; private set; }
    public int CurrentPlayerIndex { get; private set; }
    private int _moveCount = 0;

    private const int BOARD_SIZE = 30; // Kích thước bàn cờ [cite: 37]

    public GameRoom(string roomId)
    {
        RoomId = roomId;
    }

    public void AddPlayer(Player player)
    {
        // Thêm kiểm tra trạng thái phòng
        if (State != RoomState.Waiting) return;

        Players.Add(player);
    }

    // Phương thức StartGame() sẽ được thêm ở bước 3

public async Task BroadcastMessageAsync(BaseMessage message, Player? excludePlayer = null)
{
    var broadcastTasks = new List<Task>();
    
    // Lọc ra những người chơi hợp lệ để gửi tin
    var recipients = Players.Where(p => p != excludePlayer && p.IsConnected && p.ActiveConnection != null);

    foreach (var player in recipients)
    {
        // Thêm tác vụ gửi tin của mỗi người vào một danh sách
        broadcastTasks.Add(player.ActiveConnection!.SendMessageAsync(message));
    }

    // Chờ cho tất cả các tác vụ gửi tin hoàn thành
    // Lợi ích: Gửi đồng thời và không bị dừng lại nếu một tác vụ lỗi
    await Task.WhenAll(broadcastTasks);
}

    public void StartGame()
    {
        Console.WriteLine($"Game starting in room {RoomId}...");
        this.State = RoomState.Playing;

        // 1. Xáo trộn danh sách người chơi để có thứ tự ngẫu nhiên
        var random = new Random();
        var shuffledPlayers = Players.OrderBy(p => random.Next()).ToList();
        Players.Clear();
        Players.AddRange(shuffledPlayers);

        // 2. Khởi tạo bàn cờ 20x20
        this.Board = new int[BOARD_SIZE, BOARD_SIZE]; // Mặc định các giá trị là 0 (ô trống)

        // 3. Gán người đi đầu tiên
        this.CurrentPlayerIndex = 0;

        // 4. Chuẩn bị và gửi thông báo GAME_START
        var playerInfoList = Players
            .Select((player, index) => new PlayerInfo { PlayerName = player.PlayerName, PlayerId = index, SessionToken = player.SessionToken })
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

        // Dùng Task.Run để không block luồng hiện tại
        _ = BroadcastMessageAsync(notification);
    }
    public void ProcessPlayerMove(Player player, int x, int y)
    {
        // 1. Xác thực
        if (this.Board == null) return;
        if (this.State != RoomState.Playing) return; // Game chưa bắt đầu
        if (this.Players[this.CurrentPlayerIndex] != player) return; // Không phải lượt của người chơi này
        if (x < 0 || x >= BOARD_SIZE || y < 0 || y >= BOARD_SIZE) return; // Tọa độ ngoài bàn cờ
        if (this.Board[x, y] != 0) return; // Ô này đã được đánh

        // 2. Cập nhật bàn cờ
        // Gán PlayerId (0, 1, 2, hoặc 3) vào ô. Chú ý: Ta sẽ cộng 1 để phân biệt với ô trống (0).
        this.Board[x, y] = this.CurrentPlayerIndex + 1;
        _moveCount++;

        MoveHistory.Add(new MoveInfo { X = x, Y = y, PlayerId = this.CurrentPlayerIndex });

        // 3. Thông báo cho mọi người về nước đi mới
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

        // 4. Kiểm tra thắng
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
            return; // Dừng lại, không chuyển lượt nữa
        }

        //Kiểm tra hòa (khi bàn cờ đầy)
        if (_moveCount >= BOARD_SIZE * BOARD_SIZE)
        {
            this.State = RoomState.Finished;
            var gameOverNotif = new GameOverNotification
            {
                Type = "GAME_OVER",
                Payload = new GameOverPayload // Create the payload
                {
                    IsDraw = true,
            // WinnerId can be a default value like -1 for a draw
                WinnerId = -1 
                }
            };
            _ = BroadcastMessageAsync(gameOverNotif);
            Console.WriteLine($"Game over in room {RoomId}. It's a draw.");
            return;
        }


        // 5. Chuyển lượt cho người chơi tiếp theo
        do
        {
            this.CurrentPlayerIndex = (this.CurrentPlayerIndex + 1) % this.Players.Count;
        } while (!this.Players[this.CurrentPlayerIndex].IsConnected);

        // 6. Thông báo về lượt đi mới
        var turnUpdateNotif = new TurnUpdateNotification
        {
            Type = "TURN_UPDATE",
            Payload = new TurnUpdatePayload
            {
                NextPlayerId = this.CurrentPlayerIndex
            }
        };
        _ = BroadcastMessageAsync(turnUpdateNotif);
    }
    private bool CheckWinCondition(int lastX, int lastY)
    {
        if (this.Board == null) return false;
        int playerMark = this.Board[lastX, lastY]; // Lấy dấu của người chơi (1-4)
        if (playerMark == 0) return false;

        // Kiểm tra 4 hướng: Ngang, Dọc, Chéo chính, Chéo phụ
        // Hướng 1: Ngang (-)
        int count = 1;
        for (int i = 1; i < 5; i++) { if (lastY + i < BOARD_SIZE && this.Board[lastX, lastY + i] == playerMark) count++; else break; }
        for (int i = 1; i < 5; i++) { if (lastY - i >= 0 && this.Board[lastX, lastY - i] == playerMark) count++; else break; }
        if (count >= 5) return true;

        // Hướng 2: Dọc (|)
        count = 1;
        for (int i = 1; i < 5; i++) { if (lastX + i < BOARD_SIZE && this.Board[lastX + i, lastY] == playerMark) count++; else break; }
        for (int i = 1; i < 5; i++) { if (lastX - i >= 0 && this.Board[lastX - i, lastY] == playerMark) count++; else break; }
        if (count >= 5) return true;

        // Hướng 3: Chéo chính (\)
        count = 1;
        for (int i = 1; i < 5; i++) { if (lastX + i < BOARD_SIZE && lastY + i < BOARD_SIZE && this.Board[lastX + i, lastY + i] == playerMark) count++; else break; }
        for (int i = 1; i < 5; i++) { if (lastX - i >= 0 && lastY - i >= 0 && this.Board[lastX - i, lastY - i] == playerMark) count++; else break; }
        if (count >= 5) return true;

        // Hướng 4: Chéo phụ (/)
        count = 1;
        for (int i = 1; i < 5; i++) { if (lastX + i < BOARD_SIZE && lastY - i >= 0 && this.Board[lastX + i, lastY - i] == playerMark) count++; else break; }
        for (int i = 1; i < 5; i++) { if (lastX - i >= 0 && lastY + i < BOARD_SIZE && this.Board[lastX - i, lastY + i] == playerMark) count++; else break; }
        if (count >= 5) return true;

        return false; // Không thắng
    }
    public async Task HandlePlayerDisconnection(Player disconnectedPlayer)
{
    // Đánh dấu người chơi đã mất kết nối
    disconnectedPlayer.ActiveConnection = null;
    int disconnectedPlayerId = Players.IndexOf(disconnectedPlayer);

    Console.WriteLine($"Player {disconnectedPlayer.PlayerName} disconnected. Starting 30s timer...");

    // Thông báo cho các client khác
    var notification = new PlayerDisconnectedNotification // <-- Model này bạn đã tạo trước đó
    {
        Type = "PLAYER_DISCONNECTED",
        PlayerId = disconnectedPlayerId,
        ReconnectTime = 30
    };
    await BroadcastMessageAsync(notification, excludePlayer: disconnectedPlayer);


    // Bắt đầu đếm ngược
    await Task.Delay(30000); // Chờ 30 giây

        // Sau 30 giây, kiểm tra xem người chơi đã kết nối lại chưa
        if (!disconnectedPlayer.IsConnected)
        {
            Console.WriteLine($"Player {disconnectedPlayer.PlayerName} failed to reconnect. Forfeited.");
            // Xử lý thua cuộc cho người chơi đó, game vẫn tiếp tục cho 3 người còn lại
            // Hiện tại, ta chỉ cần đảm bảo lượt đi của người này sẽ được bỏ qua.
            // Ta có thể gửi một thông báo "PlayerForfeited" nếu cần.

        // Chỉ xử lý nếu đúng là lượt của người chơi vừa bị xử thua
        if (this.CurrentPlayerIndex == disconnectedPlayerId)
        {
                // Log.Information("It was the disconnected player's turn. Advancing turn...");

                // 1. Kiểm tra xem có còn người chơi nào đang kết nối không
                if (!Players.Any(p => p.IsConnected))
                {
                    Console.WriteLine($"All players have disconnected. Ending game in room {RoomId}.");
                    this.State = RoomState.Finished;
                    return; // Thoát khỏi phương thức để dừng game
                }

                // 2. Nếu còn, vòng lặp tìm người chơi tiếp theo bây giờ đã an toàn
                do
                {
                    this.CurrentPlayerIndex = (this.CurrentPlayerIndex + 1) % this.Players.Count;
                } while (!this.Players[this.CurrentPlayerIndex].IsConnected);

                // Gửi thông báo lượt đi mới cho tất cả người chơi còn lại
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
    }
}
}
// LobbyManager.cs
using System;
using System.Collections.Concurrent;

public static class LobbyManager
{
    // Dùng ConcurrentDictionary để an toàn khi truy cập từ nhiều luồng
    private static readonly ConcurrentDictionary<string, GameRoom> _rooms = new();
    private static readonly object _roomLock = new object(); // Dùng để khóa khi tìm và tạo phòng

    public static GameRoom CreateRoom()
    {
        // Tạo một ID phòng ngẫu nhiên, đơn giản
        var roomId = Guid.NewGuid().ToString("N").Substring(0, 6).ToUpper();
        var room = new GameRoom(roomId);

        // Cố gắng thêm phòng vào Dictionary, nếu thất bại thì thử lại
        while (!_rooms.TryAdd(room.RoomId, room))
        {
            room = new GameRoom(Guid.NewGuid().ToString("N").Substring(0, 6).ToUpper());
        }

        Console.WriteLine($"Room created: {room.RoomId}");
        return room;
    }

    public static GameRoom? GetRoom(string roomId)
    {
        _rooms.TryGetValue(roomId, out var room);
        return room;
    }
    public static void RemoveRoom(string roomId)
    {
        if (_rooms.TryRemove(roomId, out _))
        {
            Console.WriteLine($"Room {roomId} has been removed.");
        }
    }
    // PHƯƠNG THỨC MỚI: TRÁI TIM CỦA HỆ THỐNG MATCHMAKING
    public static GameRoom FindOrCreateRoomForPlayer(Player player)
    {
        // Lock để đảm bảo không có 2 người chơi cùng lúc tìm và tạo phòng, tránh race condition
        lock (_roomLock)
        {
            // 1. Tìm phòng tốt nhất: phòng đang chờ và có nhiều người nhất nhưng chưa đầy
            GameRoom? bestRoom = _rooms.Values
                .Where(r => r.State == RoomState.Waiting && r.Players.Count < 4)
                .OrderByDescending(r => r.Players.Count)
                .FirstOrDefault();

            // 2. Nếu tìm thấy phòng phù hợp, cho người chơi vào phòng đó
            if (bestRoom != null)
            {
                Console.WriteLine($"Match found for player {player.PlayerName}. Joining room {bestRoom.RoomId}.");
                return bestRoom;
            }
            // 3. Nếu không, tạo một phòng mới và cho người chơi vào
            else
            {
                Console.WriteLine($"No suitable room found for {player.PlayerName}. Creating a new room.");
                var newRoom = CreateRoom();
                return newRoom;
            }
        }
    }
    public static List<RoomInfo> GetAvailableRooms()
    {
        var availableRooms = new List<RoomInfo>();

        // Duyệt qua tất cả các phòng đang có trên server
        foreach (var room in _rooms.Values)
        {
            // Chỉ lấy những phòng đang ở trạng thái chờ và chưa đầy
            if (room.State == RoomState.Waiting && room.Players.Count < 4 && room.Host != null)
            {
                availableRooms.Add(new RoomInfo
                {
                    RoomId = room.RoomId,
                    HostName = room.Host.PlayerName,
                    PlayerCount = room.Players.Count
                });
            }
        }
        return availableRooms;
    }
    public static void StartAfkCheckService()
    {
        // Task.Run để chạy tiến trình này trên một luồng riêng biệt, không làm ảnh hưởng đến server chính
        Task.Run(async () =>
        {
            // Vòng lặp vô tận để dịch vụ chạy mãi mãi
            while (true)
            {
                // Đặt thời gian quét, ví dụ mỗi phút một lần
                await Task.Delay(TimeSpan.FromMinutes(1));
                

                Console.WriteLine("[AFK Check] Scanning for inactive rooms...");

                // Lấy ra danh sách các phòng thỏa mãn điều kiện:
                // 1. Đang ở trạng thái chờ (Waiting)
                // 2. Không đang trong quá trình kiểm tra
                // 3. Đã không có hoạt động gì trong hơn 10 phút
                var inactiveRooms = _rooms.Values
                    .Where(r => r.State == RoomState.Waiting &&
                                !r.IsInReadinessCheck &&
                                (DateTime.UtcNow - r.LastActivityTime).TotalMinutes > 10)
                    .ToList();

                foreach (var room in inactiveRooms)
                {
                    Console.WriteLine($"[AFK Check] Room {room.RoomId} is inactive. Initiating readiness check.");

                    // Bắt đầu quá trình kiểm tra cho từng phòng không hoạt động
                    // Dùng _ = để chạy tác vụ mà không cần đợi nó hoàn thành
                    _ = room.InitiateReadinessCheck();
                }
            }
        });
    }
}
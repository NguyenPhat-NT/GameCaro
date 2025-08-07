// LobbyManager.cs
using System;
using System.Collections.Concurrent;

public static class LobbyManager
{
    // Dùng ConcurrentDictionary để an toàn khi truy cập từ nhiều luồng
    private static readonly ConcurrentDictionary<string, GameRoom> _rooms = new();

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
}
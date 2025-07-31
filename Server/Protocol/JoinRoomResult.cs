// Protocol/JoinRoomResult.cs
using System.Collections.Generic;
using System.Text.Json.Serialization;

public class JoinRoomResult : BaseMessage
{
    [JsonPropertyName("Success")]
    public bool Success { get; set; }

    [JsonPropertyName("Message")]
    public string? Message { get; set; } // "Phòng không tồn tại", "Phòng đã đầy",...

    [JsonPropertyName("RoomId")]
    public string? RoomId { get; set; }

    [JsonPropertyName("Players")]
    public List<PlayerInfo>? Players { get; set; } // Danh sách người chơi đã có trong phòng
    public string? SessionToken { get; set; }
}

// Lớp phụ để chứa thông tin người chơi
public class PlayerInfo
{
    public string? PlayerName { get; set; }
    public int PlayerId { get; set; }
}
public class ReconnectRequest : BaseMessage
{
    [JsonPropertyName("RoomId")]
    public string? RoomId { get; set; }

    [JsonPropertyName("SessionToken")]
    public string? SessionToken { get; set; }
}
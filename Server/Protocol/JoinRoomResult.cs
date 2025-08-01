// Protocol/JoinRoomResult.cs
using System.Collections.Generic;
using System.Text.Json.Serialization;

public class JoinRoomResult : BaseMessage
{
    public JoinResultPayload? Payload { get; set; }
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
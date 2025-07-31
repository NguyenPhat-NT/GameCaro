// Protocol/JoinRoomRequest.cs
using System.Text.Json.Serialization;

public class JoinRoomRequest : BaseMessage
{
    [JsonPropertyName("PlayerName")]
    public string? PlayerName { get; set; }

    [JsonPropertyName("RoomId")]
    public string? RoomId { get; set; }
}

// Protocol/PlayerJoinedNotification.cs
using System.Text.Json.Serialization;

public class PlayerJoinedNotification : BaseMessage
{
    [JsonPropertyName("PlayerName")]
    public string PlayerName { get; set; }

    [JsonPropertyName("PlayerId")]
    public int PlayerId { get; set; } // ID của người chơi trong phòng (0-3)
}
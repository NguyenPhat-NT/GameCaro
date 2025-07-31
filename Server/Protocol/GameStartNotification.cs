// Protocol/GameStartNotification.cs
using System.Collections.Generic;
using System.Text.Json.Serialization;

public class GameStartNotification : BaseMessage
{
    [JsonPropertyName("BoardSize")]
    public int BoardSize { get; set; }

    [JsonPropertyName("Players")]
    public List<PlayerInfo>? Players { get; set; } // Danh sách người chơi theo thứ tự lượt đi mới

    [JsonPropertyName("StartingPlayerId")]
    public int StartingPlayerId { get; set; } // ID của người đi trước
}
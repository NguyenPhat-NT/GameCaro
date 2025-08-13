using System.Collections.Generic;
using System.Text.Json.Serialization;

public class ReturnToLobbyPayload
{
    // Gửi lại danh sách người chơi còn lại trong phòng
    [JsonPropertyName("Players")]
    public List<PlayerInfo> Players { get; set; }
}
// Protocol/GameOverNotification.cs
using System.Collections.Generic;
using System.Text.Json.Serialization;

public class GameOverNotification : BaseMessage
{
    [JsonPropertyName("WinnerId")]
    public int WinnerId { get; set; } // ID của người chiến thắng

    [JsonPropertyName("IsDraw")]
    public bool IsDraw { get; set; } = false;

    // (Tùy chọn) Gửi kèm tọa độ của 5 quân cờ thắng để client highlight
    // public List<Point> WinningPositions { get; set; }
}
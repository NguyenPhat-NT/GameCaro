// Protocol/BoardUpdateNotification.cs
using System.Text.Json.Serialization;

public class BoardUpdateNotification : BaseMessage
{
    [JsonPropertyName("X")]
    public int X { get; set; }

    [JsonPropertyName("Y")]
    public int Y { get; set; }

    [JsonPropertyName("PlayerId")]
    public int PlayerId { get; set; }
}
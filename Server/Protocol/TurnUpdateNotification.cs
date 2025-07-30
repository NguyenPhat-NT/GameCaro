// Protocol/TurnUpdateNotification.cs
using System.Text.Json.Serialization;

public class TurnUpdateNotification : BaseMessage
{
    [JsonPropertyName("NextPlayerId")]
    public int NextPlayerId { get; set; }
}
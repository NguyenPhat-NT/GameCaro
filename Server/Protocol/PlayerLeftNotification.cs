// Server/Protocol/PlayerLeftNotification.cs
using System.Text.Json.Serialization;

public class PlayerLeftNotification : BaseMessage
{
    [JsonPropertyName("Payload")]
    public PlayerLeftPayload? Payload { get; set; }
}
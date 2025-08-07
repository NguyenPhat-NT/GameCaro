// Server/Protocol/PlayerSurrenderedNotification.cs
using System.Text.Json.Serialization;

public class PlayerSurrenderedNotification : BaseMessage
{
    [JsonPropertyName("Payload")]
    public PlayerSurrenderedPayload? Payload { get; set; }
}
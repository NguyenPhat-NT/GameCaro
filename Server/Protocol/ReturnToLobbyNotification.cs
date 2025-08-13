// Server/Protocol/ReturnToLobbyNotification.cs
using System.Text.Json.Serialization;

public class ReturnToLobbyNotification : BaseMessage
{
    [JsonPropertyName("Payload")]
    public ReturnToLobbyPayload Payload { get; set; }

    public ReturnToLobbyNotification()
    {
        Type = "RETURN_TO_LOBBY";
    }
}
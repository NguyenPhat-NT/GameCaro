// Server/Protocol/ChatMessageReceivedNotification.cs

public class ChatMessageReceivedNotification : BaseMessage
{
    [System.Text.Json.Serialization.JsonPropertyName("Payload")]
    public ChatMessageReceivedPayload? Payload { get; set; }
}
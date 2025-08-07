// Server/Protocol/Payloads/ChatMessageReceivedPayload.cs

public class ChatMessageReceivedPayload
{
    [System.Text.Json.Serialization.JsonPropertyName("PlayerId")]
    public int PlayerId { get; set; }

    [System.Text.Json.Serialization.JsonPropertyName("PlayerName")]
    public string? PlayerName { get; set; }

    [System.Text.Json.Serialization.JsonPropertyName("Message")]
    public string? Message { get; set; }
}
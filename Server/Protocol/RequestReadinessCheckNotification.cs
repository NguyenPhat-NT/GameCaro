using System.Text.Json.Serialization;

public class RequestReadinessCheckNotification : BaseMessage
{
    [JsonPropertyName("Payload")]
    public RequestReadinessCheckPayload Payload { get; set; }
}
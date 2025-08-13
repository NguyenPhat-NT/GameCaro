using System.Text.Json.Serialization;

public class RequestReadinessCheckPayload
{
    [JsonPropertyName("Timeout")]
    public int Timeout { get; set; } // Thời gian client có để phản hồi (giây)
}
// Server/Protocol/Payloads/PlayerLeftPayload.cs
using System.Text.Json.Serialization;

public class PlayerLeftPayload
{
    [JsonPropertyName("PlayerId")]
    public int PlayerId { get; set; }

    [JsonPropertyName("PlayerName")]
    public string? PlayerName { get; set; }
}
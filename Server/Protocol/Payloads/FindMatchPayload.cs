// Server/Protocol/Payloads/FindMatchPayload.cs
using System.Text.Json.Serialization;

public class FindMatchPayload
{
    [JsonPropertyName("PlayerName")]
    public string? PlayerName { get; set; }
}
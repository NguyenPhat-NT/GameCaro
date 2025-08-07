// Server/Protocol/Payloads/PlayerSurrenderedPayload.cs
using System.Text.Json.Serialization;

public class PlayerSurrenderedPayload
{
    [JsonPropertyName("PlayerId")]
    public int PlayerId { get; set; }
}
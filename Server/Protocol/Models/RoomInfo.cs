// Server/Protocol/Models/RoomInfo.cs
using System.Text.Json.Serialization;

public class RoomInfo
{
    [JsonPropertyName("RoomId")]
    public string RoomId { get; set; }

    [JsonPropertyName("HostName")]
    public string HostName { get; set; }

    [JsonPropertyName("PlayerCount")]
    public int PlayerCount { get; set; }
}
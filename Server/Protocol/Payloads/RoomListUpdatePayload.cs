// Server/Protocol/Payloads/RoomListUpdatePayload.cs
using System.Collections.Generic;
using System.Text.Json.Serialization;

public class RoomListUpdatePayload
{
    [JsonPropertyName("Rooms")]
    public List<RoomInfo> Rooms { get; set; }
}
// Server/Protocol/RoomListUpdateResponse.cs
using System.Text.Json.Serialization;

public class RoomListUpdateResponse : BaseMessage
{
    [JsonPropertyName("Payload")]
    public RoomListUpdatePayload Payload { get; set; }
}
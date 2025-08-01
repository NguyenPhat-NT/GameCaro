// Protocol/RoomCreatedResponse.cs
using System.Text.Json.Serialization;

public class RoomCreatedResponse : BaseMessage
{
    [JsonPropertyName("Payload")]
    public RoomCreatedPayload? Payload { get; set; }
}
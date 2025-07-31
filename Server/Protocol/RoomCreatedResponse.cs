// Models/RoomCreatedResponse.cs
using System.Text.Json.Serialization;

// Kế thừa từ BaseMessage để có sẵn thuộc tính "Type"
public class RoomCreatedResponse : BaseMessage
{
    [JsonPropertyName("RoomId")]
    public string? RoomId { get; set; }
    public string? SessionToken { get; set; }
}
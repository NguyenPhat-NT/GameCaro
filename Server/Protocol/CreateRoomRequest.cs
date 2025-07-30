// Models/CreateRoomRequest.cs
using System.Text.Json.Serialization;

public class CreateRoomRequest
{
    [JsonPropertyName("PlayerName")]
    public string PlayerName { get; set; }
}
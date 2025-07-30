// Protocol/MakeMoveRequest.cs
using System.Text.Json.Serialization;

public class MakeMoveRequest : BaseMessage
{
    [JsonPropertyName("X")]
    public int X { get; set; }

    [JsonPropertyName("Y")]
    public int Y { get; set; }
}
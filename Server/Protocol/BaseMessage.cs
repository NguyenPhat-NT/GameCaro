// Models/BaseMessage.cs
using System.Text.Json.Serialization;

public class BaseMessage
{
    [JsonPropertyName("Type")]
    public string? Type { get; set; }
}
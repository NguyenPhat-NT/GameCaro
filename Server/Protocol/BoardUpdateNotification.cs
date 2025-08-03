// Protocol/BoardUpdateNotification.cs
using System.Text.Json.Serialization;

public class BoardUpdateNotification : BaseMessage
{
    public BoardUpdatePayload? Payload { get; set; }
}
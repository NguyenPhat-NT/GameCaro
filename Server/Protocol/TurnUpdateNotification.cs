// Protocol/TurnUpdateNotification.cs
using System.Text.Json.Serialization;

public class TurnUpdateNotification : BaseMessage
{
    public TurnUpdatePayload? Payload { get; set; }
}
// Protocol/GameOverNotification.cs
using System.Collections.Generic;
using System.Text.Json.Serialization;

public class GameOverNotification : BaseMessage
{
    public GameOverPayload? Payload { get; set; }
}
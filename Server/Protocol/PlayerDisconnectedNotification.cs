// Protocol/PlayerDisconnectedNotification.cs
public class PlayerDisconnectedNotification : BaseMessage
{
    public int PlayerId { get; set; }
    public int ReconnectTime { get; set; }
}
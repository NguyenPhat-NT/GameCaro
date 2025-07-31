// Protocol/PlayerReconnectedNotification.cs
public class PlayerReconnectedNotification : BaseMessage
{
    public int PlayerId { get; set; }
}
public class ReconnectResult : BaseMessage
{
    public bool Success { get; set; }

    // You can optionally send the game state back to the client
    // public GameRoom? GameState { get; set; }
}

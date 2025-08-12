// Server/Protocol/ReturnToLobbyNotification.cs

// Tin nhắn này không cần payload, client chỉ cần nhận được Type là đủ hiểu.
public class ReturnToLobbyNotification : BaseMessage
{
    public ReturnToLobbyNotification()
    {
        Type = "RETURN_TO_LOBBY";
    }
}
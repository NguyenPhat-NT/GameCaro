public class ReconnectResultPayload
{
    public bool Success { get; set; }
    public GameStatePayload? GameState { get; set; } // Sẽ là null nếu thất bại
}
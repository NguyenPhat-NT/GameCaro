public class GameStartPayload
{
    public int BoardSize { get; set; }
    public List<PlayerInfo>? Players { get; set; }
    public int StartingPlayerId { get; set; }
}
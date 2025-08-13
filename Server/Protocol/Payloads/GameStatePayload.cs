using System.Collections.Generic;

public class GameStatePayload
{
    public List<PlayerInfo> Players { get; set; }
    public List<MoveInfo> Moves { get; set; }
    public int CurrentPlayerId { get; set; }
    public List<ChatMessageReceivedPayload> ChatHistory { get; set; }
}
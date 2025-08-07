// Protocol/GameStateUpdateMessage.cs
using System.Collections.Generic;

public class GameStateUpdateMessage : BaseMessage
{
    public List<PlayerInfo>? Players { get; set; }
    public List<MoveInfo>? Moves { get; set; }
    public int CurrentPlayerId { get; set; }

    // THÊM THUỘC TÍNH MỚI: Gửi kèm lịch sử chat khi người chơi kết nối lại
    public List<ChatMessageReceivedPayload>? ChatHistory { get; set; }
}
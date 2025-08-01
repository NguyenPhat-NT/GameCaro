public class JoinResultPayload
{
    public bool Success { get; set; }
    public string? Message { get; set; }
    public string? RoomId { get; set; }
    public List<PlayerInfo>? Players { get; set; }
    public string? SessionToken { get; set; }
}
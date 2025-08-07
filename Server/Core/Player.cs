// Server/Core/Player.cs
public class Player
{
    public string PlayerName { get; }
    public string SessionToken { get; } 
    public ClientHandler? ActiveConnection { get; set; } 
    public bool IsConnected => ActiveConnection != null && ActiveConnection.IsConnected;

    // THUỘC TÍNH MỚI: Đánh dấu người chơi đã chủ động thoát
    public bool HasLeft { get; set; } = false;

    // THUỘC TÍNH MỚI: Đánh dấu người chơi đã đầu hàng
    public bool IsSurrendered { get; set; } = false;
    // THUỘC TÍNH MỚI: Đánh dấu ai là chủ phòng
    public bool IsHost { get; set; } = false;


    public Player(string playerName, ClientHandler initialConnection)
    {
        PlayerName = playerName;
        SessionToken = Guid.NewGuid().ToString();
        ActiveConnection = initialConnection;
    }
}
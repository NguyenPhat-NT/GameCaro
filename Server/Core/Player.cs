// Core/Player.cs
public class Player
{
    public string PlayerName { get; }
    public string SessionToken { get; } // Token duy nhất cho mỗi người chơi trong 1 game
    public ClientHandler ActiveConnection { get; set; } // Kết nối hiện tại, có thể là null
    public bool IsConnected => ActiveConnection != null && ActiveConnection.IsConnected;

    public Player(string playerName, ClientHandler initialConnection)
    {
        PlayerName = playerName;
        SessionToken = Guid.NewGuid().ToString(); // Tạo token ngẫu nhiên
        ActiveConnection = initialConnection;
    }
}
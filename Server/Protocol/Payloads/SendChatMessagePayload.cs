// Server/Protocol/Payloads/SendChatMessagePayload.cs

public class SendChatMessagePayload
{
    // Dùng System.Text.Json.Serialization để đảm bảo tên key là "Message" khi chuyển thành JSON
    [System.Text.Json.Serialization.JsonPropertyName("Message")]
    public string? Message { get; set; }
}
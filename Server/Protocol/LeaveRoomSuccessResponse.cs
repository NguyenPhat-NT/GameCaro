// Server/Protocol/LeaveRoomSuccessResponse.cs

// Tin nhắn này không cần payload, chỉ cần Type là đủ để client xác nhận.
public class LeaveRoomSuccessResponse : BaseMessage
{
    public LeaveRoomSuccessResponse()
    {
        Type = "LEAVE_ROOM_SUCCESS";
    }
}
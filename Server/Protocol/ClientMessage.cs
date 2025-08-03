// Protocol/ClientMessage.cs
public class ClientMessage<T> : BaseMessage
{
    public T? Payload { get; set; }
}
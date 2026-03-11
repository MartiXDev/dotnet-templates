namespace MartiX.WebApi.Guards;

public static class Guard
{
  public static GuardClause Against { get; } = new();
}

public sealed class GuardClause
{
  public T Null<T>(T? input, string message)
    where T : class
  {
    return input ?? throw new InvalidOperationException(message);
  }
}

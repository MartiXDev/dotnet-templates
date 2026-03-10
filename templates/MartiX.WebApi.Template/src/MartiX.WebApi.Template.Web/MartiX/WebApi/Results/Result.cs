namespace MartiX.WebApi.Results;

public enum ResultStatus
{
  Ok,
  Invalid,
  NotFound
}

public class ValidationError(string errorMessage, string? identifier = null)
{
  public string ErrorMessage { get; } = errorMessage;
  public string Identifier { get; } = identifier ?? string.Empty;
}

public class Result
{
  protected Result(
    ResultStatus status,
    IEnumerable<string>? errors = null,
    IEnumerable<ValidationError>? validationErrors = null)
  {
    Status = status;
    Errors = errors?.ToArray() ?? [];
    ValidationErrors = validationErrors?.ToArray() ?? [];
  }

  public ResultStatus Status { get; }
  public IReadOnlyList<string> Errors { get; }
  public IReadOnlyList<ValidationError> ValidationErrors { get; }
  public bool IsSuccess => Status == ResultStatus.Ok;

  public static Result Success() => new(ResultStatus.Ok);

  public static Result<TValue> Success<TValue>(TValue value) => new(value, ResultStatus.Ok);

  public static Result NotFound(string? error = null) =>
    new(ResultStatus.NotFound, string.IsNullOrWhiteSpace(error) ? [] : [error]);

  public static Result Invalid(params ValidationError[] validationErrors) =>
    new(ResultStatus.Invalid, validationErrors: validationErrors);
}

public sealed class Result<TValue> : Result
{
  private readonly TValue? _value;

  internal Result(
    TValue value,
    ResultStatus status,
    IEnumerable<string>? errors = null,
    IEnumerable<ValidationError>? validationErrors = null)
    : base(status, errors, validationErrors)
  {
    _value = value;
  }

  public TValue Value => Status == ResultStatus.Ok
    ? _value!
    : throw new InvalidOperationException($"Result value is not available when status is '{Status}'.");

  public static Result<TValue> Success(TValue value) => new(value, ResultStatus.Ok);

  public new static Result<TValue> NotFound(string? error = null) =>
    new(default!, ResultStatus.NotFound, string.IsNullOrWhiteSpace(error) ? [] : [error]);

  public new static Result<TValue> Invalid(params ValidationError[] validationErrors) =>
    new(default!, ResultStatus.Invalid, validationErrors: validationErrors);

  public static implicit operator Result<TValue>(TValue value) => Success(value);
}

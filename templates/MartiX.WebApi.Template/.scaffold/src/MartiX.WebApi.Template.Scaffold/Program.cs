using System.Diagnostics.CodeAnalysis;
using System.Globalization;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;

return ScaffoldApplication.Run(args);

internal static partial class ScaffoldApplication
{
  private static readonly JsonSerializerOptions JsonOptions = new()
  {
    PropertyNameCaseInsensitive = true,
    WriteIndented = true
  };

  [SuppressMessage("Design", "CA1031:Do not catch general exception types", Justification = "CLI entry point reports failures and returns a non-zero exit code.")]
  public static int Run(string[] args)
  {
    if (args.Length == 0 || args[0] is "--help" or "-h" or "help")
    {
      PrintUsage();
      return args.Length == 0 ? 1 : 0;
    }

    var normalizedCommand = args[0].Trim().ToUpperInvariant();
    if (normalizedCommand is not ("BOOTSTRAP" or "UPDATE" or "VERIFY"))
    {
      Console.Error.WriteLine($"Unsupported scaffold command '{args[0]}'.");
      PrintUsage();
      return 1;
    }

    var command = normalizedCommand switch
    {
      "BOOTSTRAP" => "bootstrap",
      "UPDATE" => "update",
      _ => "verify"
    };

    ScaffoldOptions options;

    try
    {
      options = ScaffoldOptions.Parse(command, args[1..]);
    }
    catch (ArgumentException ex)
    {
      Console.Error.WriteLine(ex.Message);
      PrintUsage();
      return 1;
    }

    try
    {
      Execute(options);
      return 0;
    }
    catch (Exception ex)
    {
      Console.Error.WriteLine($"Scaffold command '{command}' failed: {ex.Message}");
      return 1;
    }
  }

  private static void Execute(ScaffoldOptions options)
  {
    var repoRoot = Path.GetFullPath(options.RepoRoot ?? Directory.GetCurrentDirectory());
    var scaffoldRoot = Path.Combine(repoRoot, ".scaffold");
    var settingsPath = Path.Combine(scaffoldRoot, "scaffold.settings.json");
    var manifestPath = Path.Combine(scaffoldRoot, "assets", "asset-manifest.json");

    if (!Directory.Exists(scaffoldRoot))
    {
      throw new InvalidOperationException($"Expected scaffold root '{scaffoldRoot}' was not found.");
    }

    var settings = LoadRequiredJson<ScaffoldSettings>(settingsPath, "scaffold settings");
    var manifest = LoadRequiredJson<AssetManifest>(manifestPath, "asset manifest");

    if (string.IsNullOrWhiteSpace(settings.ProjectName))
    {
      throw new InvalidOperationException("Scaffold settings must provide a projectName value.");
    }

    if (string.IsNullOrWhiteSpace(settings.Framework))
    {
      throw new InvalidOperationException("Scaffold settings must provide a framework value.");
    }

    var assetsRoot = Path.GetDirectoryName(manifestPath)
      ?? throw new InvalidOperationException($"Unable to determine assets root from '{manifestPath}'.");

    var selectedAssetIds = ResolveAssetIds(options.Command, manifest);
    if (selectedAssetIds.Length == 0)
    {
      Console.WriteLine($"No assets are configured for '{options.Command}'.");
      return;
    }

    var assetsById = manifest.Assets
      .GroupBy(asset => asset.Id, StringComparer.OrdinalIgnoreCase)
      .ToDictionary(group => group.Key, group => group.Single(), StringComparer.OrdinalIgnoreCase);

    var context = BuildContext(settings, manifest, options, repoRoot);

    foreach (var assetId in selectedAssetIds)
    {
      if (!assetsById.TryGetValue(assetId, out var asset))
      {
        throw new InvalidOperationException($"Asset '{assetId}' is referenced by command '{options.Command}' but is not defined.");
      }

      ProcessAsset(asset, assetsRoot, repoRoot, context, options.Command, options.DryRun);
    }
  }

  private static Dictionary<string, string> BuildContext(
    ScaffoldSettings settings,
    AssetManifest manifest,
    ScaffoldOptions options,
    string repoRoot)
  {
    var context = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
    {
      ["ProjectName"] = settings.ProjectName,
      ["Framework"] = settings.Framework,
      ["RepoRoot"] = repoRoot,
      ["Command"] = options.Command,
      ["ScaffoldSchemaVersion"] = manifest.SchemaVersion.ToString(CultureInfo.InvariantCulture)
    };

    foreach (var variable in options.Variables)
    {
      context[variable.Key] = variable.Value;
    }

    return context;
  }

  private static void ProcessAsset(
    AssetDefinition asset,
    string assetsRoot,
    string repoRoot,
    IReadOnlyDictionary<string, string> context,
    string command,
    bool dryRun)
  {
    var sourcePath = Path.GetFullPath(Path.Combine(assetsRoot, asset.Source));
    var targetPath = Path.GetFullPath(Path.Combine(repoRoot, asset.Target));

    if (!IsPathWithinRoot(sourcePath, assetsRoot))
    {
      throw new InvalidOperationException($"Asset source '{asset.Source}' escapes the assets root.");
    }

    if (!IsPathWithinRoot(targetPath, repoRoot))
    {
      throw new InvalidOperationException($"Asset target '{asset.Target}' escapes the repository root.");
    }

    if (!File.Exists(sourcePath))
    {
      throw new FileNotFoundException($"Asset source '{sourcePath}' was not found.");
    }

    var expectedBytes = GetExpectedContentBytes(asset, sourcePath, context);

    if (command.Equals("verify", StringComparison.OrdinalIgnoreCase))
    {
      if (!File.Exists(targetPath))
      {
        throw new InvalidOperationException($"Scaffold-managed asset '{asset.Target}' is missing.");
      }

      var currentBytes = File.ReadAllBytes(targetPath);
      if (!currentBytes.AsSpan().SequenceEqual(expectedBytes))
      {
        throw new InvalidOperationException($"Scaffold-managed asset '{asset.Target}' is out of date.");
      }

      Console.WriteLine($"verify {asset.Target}");
      return;
    }

    var operation = asset.Mode.Equals("copy", StringComparison.OrdinalIgnoreCase) ? "copy" : "write";
    Console.WriteLine($"{(dryRun ? "[dry-run] would " : string.Empty)}{operation} {asset.Target}");

    if (dryRun)
    {
      return;
    }

    Directory.CreateDirectory(Path.GetDirectoryName(targetPath)
      ?? throw new InvalidOperationException($"Unable to determine target directory for '{targetPath}'."));
    File.WriteAllBytes(targetPath, expectedBytes);
  }

  private static byte[] GetExpectedContentBytes(
    AssetDefinition asset,
    string sourcePath,
    IReadOnlyDictionary<string, string> context)
  {
    if (asset.Mode.Equals("copy", StringComparison.OrdinalIgnoreCase))
    {
      return File.ReadAllBytes(sourcePath);
    }

    if (!asset.Mode.Equals("template", StringComparison.OrdinalIgnoreCase))
    {
      throw new InvalidOperationException($"Unsupported asset mode '{asset.Mode}' for asset '{asset.Id}'.");
    }

    var renderedContent = RenderTemplate(File.ReadAllText(sourcePath), context);
    renderedContent = NormalizeLineEndings(renderedContent, asset.LineEndings);
    return new UTF8Encoding(encoderShouldEmitUTF8Identifier: false).GetBytes(renderedContent);
  }

  private static bool IsPathWithinRoot(string path, string root)
  {
    var normalizedRoot = Path.TrimEndingDirectorySeparator(Path.GetFullPath(root)) + Path.DirectorySeparatorChar;
    var normalizedPath = Path.GetFullPath(path);
    return normalizedPath.StartsWith(normalizedRoot, StringComparison.OrdinalIgnoreCase)
      || normalizedPath.Equals(Path.TrimEndingDirectorySeparator(normalizedRoot), StringComparison.OrdinalIgnoreCase);
  }

  private static string RenderTemplate(string template, IReadOnlyDictionary<string, string> context)
  {
    return PlaceholderRegex().Replace(template, match =>
    {
      var key = match.Groups["key"].Value;
      if (!context.TryGetValue(key, out var value))
      {
        throw new InvalidOperationException($"Template placeholder '{key}' does not have a value.");
      }

      return value;
    });
  }

  private static string NormalizeLineEndings(string content, string? lineEndings)
  {
    if (string.IsNullOrWhiteSpace(lineEndings) || lineEndings.Equals("preserve", StringComparison.OrdinalIgnoreCase))
    {
      return content;
    }

    var normalized = content.Replace("\r\n", "\n", StringComparison.Ordinal).Replace("\r", "\n", StringComparison.Ordinal);

    return lineEndings.ToUpperInvariant() switch
    {
      "LF" => normalized,
      "CRLF" => normalized.Replace("\n", "\r\n", StringComparison.Ordinal),
      _ => throw new InvalidOperationException($"Unsupported line ending mode '{lineEndings}'.")
    };
  }

  private static string[] ResolveAssetIds(string command, AssetManifest manifest)
  {
    if (!manifest.Commands.TryGetValue(command, out var definition))
    {
      return Array.Empty<string>();
    }

    return definition.Include
      .Distinct(StringComparer.OrdinalIgnoreCase)
      .ToArray();
  }

  private static T LoadRequiredJson<T>(string path, string description)
  {
    if (!File.Exists(path))
    {
      throw new FileNotFoundException($"The {description} file '{path}' was not found.");
    }

    var value = JsonSerializer.Deserialize<T>(File.ReadAllText(path), JsonOptions);
    return value ?? throw new InvalidOperationException($"The {description} file '{path}' could not be parsed.");
  }

  [SuppressMessage("Globalization", "CA1303:Do not pass literals as localized parameters", Justification = "CLI usage text is intentionally non-localized.")]
  private static void PrintUsage()
  {
    Console.WriteLine("Usage: dotnet run --project .scaffold/src/<Project>.Scaffold/<Project>.Scaffold.csproj -- <bootstrap|update|verify> [--repo-root <path>] [--dry-run] [--var Name=Value]");
  }

  [GeneratedRegex(@"\{\{\s*(?<key>[A-Za-z0-9_]+)\s*\}\}")]
  private static partial Regex PlaceholderRegex();
}

internal sealed record ScaffoldOptions(
  string Command,
  string? RepoRoot,
  bool DryRun,
  IReadOnlyDictionary<string, string> Variables)
{
  public static ScaffoldOptions Parse(string command, IReadOnlyList<string> args)
  {
    string? repoRoot = null;
    var dryRun = false;
    var variables = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);

    for (var index = 0; index < args.Count; index++)
    {
      var argument = args[index];

      if (string.IsNullOrWhiteSpace(argument))
      {
        continue;
      }

      switch (argument)
      {
        case "--repo-root":
          if (index + 1 >= args.Count)
          {
            throw new ArgumentException("Missing value for --repo-root.");
          }

          repoRoot = args[++index];
          break;

        case "--dry-run":
          dryRun = true;
          break;

        case "--var":
          if (index + 1 >= args.Count)
          {
            throw new ArgumentException("Missing value for --var.");
          }

          AddVariable(args[++index], variables);
          break;

        default:
          if (argument.StartsWith("--var=", StringComparison.Ordinal))
          {
            AddVariable(argument["--var=".Length..], variables);
            break;
          }

          throw new ArgumentException($"Unsupported argument '{argument}'.");
      }
    }

    return new ScaffoldOptions(command, repoRoot, dryRun, variables);
  }

  private static void AddVariable(string assignment, Dictionary<string, string> variables)
  {
    var separatorIndex = assignment.IndexOf('=', StringComparison.Ordinal);
    if (separatorIndex <= 0 || separatorIndex == assignment.Length - 1)
    {
      throw new ArgumentException($"Invalid variable assignment '{assignment}'. Expected Name=Value.");
    }

    var key = assignment[..separatorIndex];
    var value = assignment[(separatorIndex + 1)..];
    variables[key] = value;
  }
}

[SuppressMessage("Performance", "CA1812:Avoid uninstantiated internal classes", Justification = "Instantiated via JSON deserialization.")]
internal sealed record ScaffoldSettings(string ProjectName, string Framework);

[SuppressMessage("Performance", "CA1812:Avoid uninstantiated internal classes", Justification = "Instantiated via JSON deserialization.")]
internal sealed record AssetManifest(
  int SchemaVersion,
  IReadOnlyList<AssetDefinition> Assets,
  IReadOnlyDictionary<string, CommandDefinition> Commands);

[SuppressMessage("Performance", "CA1812:Avoid uninstantiated internal classes", Justification = "Instantiated via JSON deserialization.")]
internal sealed record AssetDefinition(
  string Id,
  string Description,
  string Source,
  string Target,
  string Mode,
  string? LineEndings);

[SuppressMessage("Performance", "CA1812:Avoid uninstantiated internal classes", Justification = "Instantiated via JSON deserialization.")]
internal sealed record CommandDefinition(
  string Description,
  IReadOnlyList<string> Include);

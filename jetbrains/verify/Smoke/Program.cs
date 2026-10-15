using Tomlyn;

var assembly = typeof(TomlSerializer).Assembly;
if (assembly.GetName().GetPublicKeyToken() is not { Length: > 0 })
    throw new InvalidOperationException("The packaged Tomlyn assembly is not strong-name signed.");

var value = TomlSerializer.Deserialize<SmokeModel>("Name = \"JetBrains\"\n");
if (value?.Name != "JetBrains")
    throw new InvalidOperationException("Tomlyn failed to deserialize the smoke TOML document.");

var serialized = TomlSerializer.Serialize(value);
if (!serialized.Contains("Name = \"JetBrains\"", StringComparison.Ordinal))
    throw new InvalidOperationException("Tomlyn failed to serialize the smoke model.");

Console.WriteLine($"Verified {assembly.GetName().Name} ({assembly.GetName().Version}) from the JetBrains package.");

public sealed class SmokeModel
{
    public string Name { get; set; } = "";
}

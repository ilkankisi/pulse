using System.Runtime.CompilerServices;

namespace Pulse.Api.Tests;

internal static class TestEnvironmentInitializer

{

[ModuleInitializer]

internal static void Initialize()

{

Environment.SetEnvironmentVariable(

"DOTNET_ENVIRONMENT",

"Testing");

    Environment.SetEnvironmentVariable(
        "ASPNETCORE_ENVIRONMENT",
        "Testing");
}

}
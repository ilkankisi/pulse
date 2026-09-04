using Xunit;

namespace Pulse.Api.Tests;

public sealed class PulseApiTests

{

[Fact]

public void MinimalHostingProgramEntryPoint_IsAvailable()

{

Assert.NotNull(typeof(global::Program));

}

}
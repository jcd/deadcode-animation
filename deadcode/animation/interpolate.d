/**
    Interpolation functions to interpolate between value of common types

    Also contains an InterpolateTimer to help interpolate using time.
*/
module deadcode.animation.interpolate;

version (unittest) import deadcode.test;

auto interpolate(T)(T beginValue, T endValue, float delta)
{
	return (endValue - beginValue) * delta + beginValue;
}

//
unittest
{
    Assert(0.5, interpolate(0.0f, 1.0f, 0.5f), "Can interpolate float using generic interpolation");
}

auto interpolate(T : int)(T beginValue, T endValue, float delta)
{
    import std.math;
	return cast(int) round((endValue - beginValue) * delta + beginValue);
}

//
unittest
{
    Assert(5, interpolate(0, 10, 0.5f), "Can interpolate int using generic interpolation");
    Assert(5, interpolate(0, 9, 0.5f), "Can interpolate int using generic interpolation and round up");
    Assert(5, interpolate(0, 11, 0.49f), "Can interpolate int using generic interpolation and round down");
}

auto interpolate(T : bool)(T beginValue, T endValue, float delta)
{
	return delta == 1.0;
}

auto interpolate(T : uint)(T beginValue, T endValue, float delta)
{
    import std.math;
	return cast(uint) round((endValue - beginValue) * delta + beginValue);
}

//
unittest
{
    Assert(5, interpolate(0, 10, 0.5f), "Can interpolate uint using generic interpolation");
    Assert(5, interpolate(0, 9, 0.5f), "Can interpolate uint using generic interpolation and round up");
    Assert(5, interpolate(0, 11, 0.49f), "Can interpolate uint using generic interpolation and round down");
}

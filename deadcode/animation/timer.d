module deadcode.animation.timer;

import core.time;
import std.math;

import deadcode.animation.mutator;
import deadcode.animation.curve;

interface Timer
{
	void reset();
	@property double currTime() const nothrow;
}

class SystemTimer : Timer
{
	void reset() {}

	@property double currTime() const nothrow
	{
		return currSystemTime;
	}

	static @property double currSystemTime() nothrow
	{
		import std.conv : to;
        static import core.time;

        auto t = MonoTime.currTime;
        auto nsecs = ticksToNSecs(t.ticks);
        auto res = dur!"nsecs"(nsecs);
		//auto res = t.to!("seconds", double)();
        TickDuration td = res.to!TickDuration();
		return core.time.to!("seconds", double)(td);
	}
}

//
unittest
{
    auto t = new SystemTimer;
    Assert(0.0 != t.currTime, "System timer can get system time");
}

class InterpolateTimer : Timer
{
	private
	{
		double _start;
		double _duration;
		Timer _timer;
	}

	@property
	{
		double start() const pure nothrow @safe { return _start; }
		double end() const pure nothrow @safe { return _start + _duration; }
		double duration() const pure nothrow @safe { return _duration; }
	}

	this(Duration duration, Timer timer = null)
	{
		this((cast(TickDuration)duration).to!("seconds",double)(), timer);
	}

	this(Duration duration, TickDuration start, Timer timer = null)
	{
		this((cast(TickDuration)duration).to!("seconds",double)(), 
             start.to!("seconds",double)(), timer);
	}

	this(double duration, Timer timer = null)
	{
		this(duration, timer is null ? SystemTimer.currSystemTime : timer.currTime, timer);
	}

	this(double duration, double start, Timer timer = null)
	{
		_timer = timer;
		_start = start;
		_duration = duration;
	}

	void reset()
	{
		_start = _timer is null ? SystemTimer.currSystemTime : _timer.currTime;
	}

	@property double currTime() const nothrow
	{
		auto timeNow = _timer is null ? SystemTimer.currSystemTime : _timer.currTime;
		if (timeNow <= _start)
			return start;
		auto dt = timeNow - _start;
		if (dt >= _duration)
			return end;
		return timeNow;
	}

	// Returns: 0..1
	@property double currTimeRelative() const
	{
		auto timeNow = _timer is null ? SystemTimer.currSystemTime : _timer.currTime;
		if (timeNow <= _start)
			return 0f;
		auto dt = timeNow - _start;
		if (dt >= _duration)
			return 1f;
		return dt / _duration;
	}
}

//
unittest
{
    class MockTimer : Timer
    {
        int calledCount = 0;

        void reset() { }
        @property double currTime() const nothrow
        {
            (cast(int)calledCount)++;
            if (calledCount == 1)
                return 1000.0;
            else if (calledCount == 2)
                return 1010.0;
            else if (calledCount == 3)
                return 1012.0;
            else 
                return 1035.0;
        }
    }

    auto t = new InterpolateTimer(20.0, new MockTimer());
    Assert(20.0, t.duration, "InterpolateTimer timer has correct duration (double constructor)");
    t = new InterpolateTimer(dur!"seconds"(20), new MockTimer());
    Assert(20.0, t.duration, "InterpolateTimer timer has correct duration (Duration constructor)");
    t = new InterpolateTimer(dur!"seconds"(20), TickDuration().from!"seconds"(1000), new MockTimer());
    Assert(1000.0, t.start, "InterpolateTimer timer has correct start (Duration,TickDuration constructor)");

    t = new InterpolateTimer(20.0, 1010.0, new MockTimer());
    Assert(20.0, t.duration, "InterpolateTimer timer has correct duration");
    Assert(1010.0, t.start, "InterpolateTimer timer has correct start");
    Assert(1010.0, t.currTime, "InterpolateTimer timer will clamp to start");
    Assert(1010.0, t.currTime, "InterpolateTimer timer will get start");
    Assert(1012.0, t.currTime, "InterpolateTimer timer will interpolate");
    Assert(1030.0, t.currTime, "InterpolateTimer timer will clamp to end");

    t = new InterpolateTimer(20.0, 1010.0, new MockTimer());
    Assert(0.0, t.currTimeRelative, "InterpolateTimer timer will relative clamp to start");
    Assert(0.0, t.currTimeRelative, "InterpolateTimer timer will relative get start");
    Assert(0.1, t.currTimeRelative, "InterpolateTimer timer will relative interpolate");
    Assert(1.0, t.currTimeRelative, "InterpolateTimer timer will relative clamp to end");

    auto mt = new MockTimer();
    t = new InterpolateTimer(20.0, 1010.0, mt);
    Assert(1010.0, t.start, "InterpolateTimer timer has correct start");
    t.now; 
    t.now;
    Assert(1012.0, t.currTime, "InterpolateTimer timer is forwarded to prepare for reset");
    t.reset();
    Assert(1035.0, t.start, "InterpolateTimer timer has correct reset start");
}


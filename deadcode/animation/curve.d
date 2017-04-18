/**
    Curves specified by a time interval that can be evaluated at any time offset.

    Curves are used for defining how values are interpolated in time. The actual
    interpolation is done by interpolation functions in deadcode.animation.interpolate;
*/
module deadcode.animation.curve;

import deadcode.animation.interpolate;

version (unittest) import deadcode.test;

//enum CurveStop
//{
//    clamp,
//    loop,
//    pingPong
//}

/** An abstract curve

    Provides a begin, end point and the posibility to evaluate the value
    of the curve at a given timeoffset.
*/
class Curve(T)
{
	// CurveStop curveStop;

	abstract @property
	{
        // Begin time of the curve interval
		double begin() const pure;

        // End time of the curve interval
		double end() const pure;
	}

    // Duration of the curve
	@property duration() const pure
	{
		return end - begin;
	}

	/**
        Returns: The value of the curve evaluted at timeOffset
    */
    abstract T eval(double timeOffset);
}

/** Curve that returns value sampled from an time/value set for the curve interval

    Outside the interval the end points of the time/value set are returned
*/
class SampleCurve(T) : Curve!T
{
	struct Sample
	{
		double x;
		T y;
	}

    private 
    {
        Range _range;
        Range _activeRange;
    }
    
	@property
	{
		double begin() const pure { return _begin; }
		double end() const pure   { return _end; }
	}

	this(Range)(double b, double e, Range range)
	{
		_begin = b;
		_end = e;
        _range = r;
	}

	float eval(double timeOffset)
	{
        // Usually the timeOffsets are queried increasingly. Therefore we keep an _activeRange 
        // which is a .save of the _range. The we assume that we can just popFront() from that
        // and get correct entries. If that assumption fails we must .save the original range again
        // and search for the correct entry to sample.
		return offset;
	}
}

/** Curve that returns a contant value for the curve interval

    Outside the interval the constant is also returned
*/
class ConstantCurve(T) : Curve!T
{
	private
	{
		double _begin;
		double _end;
		T _beginValue;
	}

	override @property
	{
		double begin() const pure { return _begin; }
		double end() const pure   { return _end; }
	}

	this(double xBegin, T yBegin, double xEnd)
	{
		_begin = xBegin;
		_end = xEnd;
		_beginValue = yBegin;
	}

	override T eval(double offset)
	{
		return _beginValue;
	}
}

//
unittest
{
    auto c = new ConstantCurve!int(1.0, 2, 2.0);
    Assert(1.0, c.begin, "ConstantCurve return begin");
    Assert(2.0, c.end, "ConstantCurve return end");
    Assert(1.0, c.duration, "ConstantCurve return duration");
    Assert(c.eval(0.0), 2, "ConstantCurve evaluates to contant before the interval");
    Assert(c.eval(1.1), 2, "ConstantCurve evaluates to contant inside the interval");
    Assert(c.eval(2.1), 2, "ConstantCurve evaluates to contant after the interval");
}

/** Curve that interpolate a line curve in the interval

    Outside the interval the value is clamp to the end values
*/
class LinearCurve(T) : Curve!T
{
	private
	{
		double _begin;
		double _end;
		T  _beginValue;
		T  _endValue;
	}

	override @property
	{
		double begin() const pure { return _begin; }
		double end() const pure   { return _end; }
	}

	this(double xBegin, T yBegin, double xEnd, T yEnd)
	{
		_begin = xBegin;
		_end = xEnd;
		_beginValue = yBegin;
		_endValue = yEnd;
	}

	override T eval(double offset)
	{
		if (offset >= _end)
			return _beginValue.interpolate(_endValue, 1);
		else if (offset < _begin)
			return _beginValue.interpolate(_endValue, 0);
		else
		{
			float delta = (offset - _begin) / (_end - _begin);
			return _beginValue.interpolate(_endValue, delta);
		}
	}
}

//
unittest
{
    auto c = new LinearCurve!int(1.0, 2, 2.0, 4);
    Assert(1.0, c.begin, "LinearCurve return begin");
    Assert(2.0, c.end, "LinearCurve return end");
    Assert(c.eval(0.0), 2, "LinearCurve evaluates to start value before the interval");
    Assert(c.eval(1.0), 2, "LinearCurve evaluates to interpolation inside the interval");
    Assert(c.eval(2.0), 4, "LinearCurve evaluates to interpolation inside the interval");
    Assert(c.eval(2.1), 4, "LinearCurve evaluates to end value after the interval");
}

LinearCurve!T linear(T)()
{
	static LinearCurve!T i;
	if (i is null)
		i = new LinearCurve!T(0, 0, 1, 1);
	return i;
}

/** Curve that interpolate a cubic curve in the interval

    Outside the interval the value is clamp to the end values
*/
class CubicCurve(T) : Curve!T
{
	private
	{
		double _begin;
		double _end;
		T  _beginValue;
		T  _endValue;
	}

	override @property
	{
		double begin() const pure { return _begin; }
		double end() const pure   { return _end; }
	}

	this(double xBegin, T yBegin, double xEnd, T yEnd)
	{
		_begin = xBegin;
		_end = xEnd;
		_beginValue = yBegin;
		_endValue = yEnd;
	}

	override T eval(double offset)
	{

		if (offset <= _begin)
			return _beginValue.interpolate(_endValue, 0);
		else if (offset >= _end)
			return _beginValue.interpolate(_endValue, 1);
		else
		{
			float delta = (offset - _begin) / (_end - _begin);
			delta -= 1;
			delta = delta*delta*delta*delta*delta + 1;
			return _beginValue.interpolate(_endValue, delta);
		}
	}
}

//
unittest
{
    auto c = new CubicCurve!double(1.0, 2.0, 2.0, 4.0);
    Assert(1.0, c.begin, "CubicCurve return begin");
    Assert(2.0, c.end, "CubicCurve return end");
    Assert(c.eval(0.0), 2.0, "CubicCurve evaluates to start value before the interval");
    Assert(c.eval(1.0), 2.0, "CubicCurve evaluates to interpolation inside the interval");
    Assert(c.eval(1.5), 3.9375, "CubicCurve evaluates to interpolation inside the interval");
    Assert(c.eval(2.0), 4.0, "CubicCurve evaluates to interpolation inside the interval");
    Assert(c.eval(2.1), 4.0, "CubicCurve evaluates to end value after the interval");
}

CubicCurve!T cubic(T)()
{
	static CubicCurve!T _cubic;
	if (_cubic is null)
		_cubic = new CubicCurve!T(0, 0, 1, 1);

	return _cubic;
}

/** Curve that interpolate a cubic bezier curve in the interval

    Outside the interval the value is clamp to the end values
*/
class CubicBezierCurve(T) : Curve!T
{
    import deadcode.math.bezier;

	private
	{
		double _begin;
		double _end;
		T  _beginValue;
		T  _endValue;

		UnitBezier _unitBezier;
	}

	//union
	//{
	//    float[4] p;
	//    struct
	//    {
	//        float p0, p1, p2, p3;
	//    }
	//}

	static immutable ease   = [0.25f, 0.1f, 0.25f, 1];
	static immutable linear = [0f, 0, 1, 1];
	static immutable easeIn = [0.42f, 0, 1, 1];
	static immutable easeOut = [0f, 0, 0.58f, 1];
	static immutable easeInOut = [0.42f, 0, 0.58f, 1];

	override @property
	{
		double begin() const pure { return _begin; }
		double end() const pure   { return _end; }
	}

	this(double xBegin, T yBegin, double xEnd, T yEnd, UnitBezier ub)
	{
		_begin = xBegin;
		_end = xEnd;
		_beginValue = yBegin;
		_endValue = yEnd;
		_unitBezier = ub;
		//p[] = ease;
	}

	override T eval(double offset)
	{

		if (offset <= _begin)
			return _beginValue.interpolate(_endValue, 0);
		else if (offset >= _end)
			return _beginValue.interpolate(_endValue, 1);
		else
		{
			double duration = _end - _begin;
			double t = (offset - _begin) / duration;
			//double e = 1-t;

			//import deadcode.math.smallvector;
			//
			//Vec2f pa = Vec2f(0,0);
			//Vec2f pb = Vec2f(p0,p1);
			//Vec2f pc = Vec2f(p2,p3);
			//Vec2f pd = Vec2f(0,0);

			//Vec2f b =      (1.0-t*t*t)*        pa +
			//          3.0 * (1.0-t*t) * t *     pb +
			//          3.0 * (1.0-t) *   t*t *   pc +
			//                            t*t*t * pd;

			//Vec2f b = pa *     (1.0-t*t*t)        +
			//    pb * (3.0 * (1.0-t*t) * t)      +
			//    pc * (3.0 * (1.0-t) *   t*t)    +
			//    pd * (t*t*t);
			//

			double epsilon = 1.0 / (200.0 * duration);
			auto y = _unitBezier.solve(t, epsilon);

			T result = _beginValue.interpolate(_endValue, y);
			//static if (is(T : CSSScaleMix))
			//    std.stdio.writeln(offset, " ", " ", _begin, " ", b);
			return result;

			//
			//auto b =     (1-t^3) * p0 +
			//         3 * (1-t^2) * t * p1 +
			//         3 * (1-t) * t^2 * p2 +
			//         t^3 * p3;
		}
	}
}


//
unittest
{
    import std.math;
    import deadcode.math.bezier;
    auto l = CubicBezierCurve!double.linear;
    auto b1 = UnitBezier(l[0], l[1], l[2], l[3]);
    auto c = new CubicBezierCurve!double(1.0, 2.0, 2.0, 4.0, b1);
    Assert(1.0, c.begin, "CubicBezierCurve return begin");
    Assert(2.0, c.end, "CubicBezierCurve return end");
    Assert(c.eval(0.0), 2.0, "CubicBezierCurve.linear evaluates to start value before the interval");
    Assert(c.eval(1.0), 2.0, "CubicBezierCurve.linear evaluates to interpolation inside the interval");
    Assert(c.eval(1.5), 3.0, "CubicBezierCurve.linear evaluates to interpolation inside the interval");
    Assert(c.eval(2.0), 4.0, "CubicBezierCurve.linear evaluates to interpolation inside the interval");
    Assert(c.eval(2.1), 4.0, "CubicBezierCurve.linear evaluates to end value after the interval");

    auto l2 = CubicBezierCurve!double.easeIn;
    auto b2 = UnitBezier(l2[0], l2[1], l2[2], l2[3]);
    c = new CubicBezierCurve!double(1.0, 2.0, 2.0, 4.0, b2);
    Assert(c.eval(0.0), 2.0, "CubicBezierCurve.easeIn evaluates to start value before the interval");
    Assert(c.eval(1.0), 2.0, "CubicBezierCurve.easeIn evaluates to interpolation inside the interval");
    Assert(approxEqual(c.eval(1.1), 2.03414), "CubicBezierCurve.easeIn evaluates to interpolation inside the interval");
    Assert(c.eval(2.0), 4.0, "CubicBezierCurve.easeIn evaluates to interpolation inside the interval");
    Assert(c.eval(2.1), 4.0, "CubicBezierCurve.easeIn evaluates to end value after the interval");
}

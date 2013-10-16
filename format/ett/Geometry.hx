package format.ett;

class Point {
	public var x:Float;
	public var y:Float;
	public inline function new( _x, _y ) {
		x = _x;
		y = _y;
	}
	public inline function rawString():String {
		return x+" "+y;
	}
	public inline function geoJSONString():String {
		return '{"type":"Point","coordinates":[$x,$y]}';
	}
}

class LineString {
	private var point:Array<Point>;
	public var length(get,never):Int;
	public inline function new( ?_point ) {
		if ( _point == null ) _point = [];
		point = _point;
	}
	public inline function rawString():String {
		var b = new StringBuf();
		var first = true;
		for ( p in point ) {
			if ( !first )
				b.add( "," );
			else
				first = false;
			b.add( p.rawString() );
		}
		return b.toString();
	}
	public inline function geoJSONString():String {
		var b = new StringBuf();
		b.add( '{"type":"LineString","coordinates":[' );
		var first = true;
		for ( p in point ) {
			if ( !first )
				b.add( "," );
			else
				first = false;
			b.add( '[${p.x},${p.y}]' );
		}
		b.add( ']}' );
		return b.toString();
	}
	public inline function push( p:Point ):Int return point.push( p );
	public inline function array():Array<Point> return point.copy();
	private function get_length() return point.length;
}

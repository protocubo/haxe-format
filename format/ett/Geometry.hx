package format.ett;

class Point {
	public var x:Float;
	public var y:Float;
	public function new( _x, _y ) {
		x = _x;
		y = _y;
	}
	public function rawString():String {
		return x+" "+y;
	}
	public function geoJSONString():String {
		return '{"type":"Point","coordinates":[$x,$y]}';
	}
}

class LineString {
	public var point:Array<Point>;
	public function new( _point ) {
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
}

// class Polygon {
// 	public var outer:LineString;
// 	public var inner:Array<LineString>;
// 	public function new( _outer, _inner ) {
// 		outer = _outer;
// 		inner = _inner;
// 	}
// }

// class MultiPolygon {
// 	public var polygon:Array<Polygon>;
// }

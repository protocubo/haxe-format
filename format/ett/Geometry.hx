package format.ett;

abstract Point( Array<Float> ) {
	public var x( get, never ):Float;
	public var y( get, never ):Float;
	public inline function new( x, y ) {
		this = [ x, y ];
	}
	public inline function rawString():String {
		return x+" "+y;
	}
	public inline function geoJSONString():String {
		return '{"type":"Point","coordinates":[$x,$y]}';
	}
	@:from @:noCompletion public inline static function fromArray( a:Array<Float> ):Point {
		if ( a.length != 2 )
			throw "Cannot cast Array<Float> to Point: Array has length != 2 ("+a.length+")";
		return cast a;
	}
	private inline function get_x():Float return this[0];
	private inline function get_y():Float return this[1];
}

abstract LineString( Array<Float> ) {
	public var length( get, never ):Int;
	public inline function new( ?shape:LineString ) {
		if ( shape != null )
			this = cast shape;
		else
			this = [];
	}
	@:arrayAccess @:noCompletion public inline function arrayGet( i:Int ):Point {
		return cast this.slice( i*2, i*2+2 );
	}
	@:arrayAccess @:noCompletion public inline function arraySet( i:Int, v:Point ):Point {
		this[i*2] = v.x;
		this[i*2+1] = v.y;
		return v;
	}
	public inline function rawString():String {
		var b = new StringBuf();
		var first = true;
		for ( i in 0...length ) {
			if ( !first )
				b.add( "," );
			else
				first = false;
			b.add( arrayGet( i ).rawString() );
		}
		return b.toString();
	}
	public inline function geoJSONString():String {
		var b = new StringBuf();
		b.add( '{"type":"LineString","coordinates":[' );
		var first = true;
		for ( i in 0...length ) {
			if ( !first )
				b.add( "," );
			else
				first = false;
			var p = arrayGet( i );
			b.add( '[${p.x},${p.y}]' );
		}
		b.add( ']}' );
		return b.toString();
	}
	public inline function push( p:Point ) {
		this.push( p.x );
		this.push( p.y );
	}
	@:from @:noCompletion public inline static function fromArrayPoint( a:Array<Point> ):LineString {
		var y = new LineString();
		for ( p in a )
			y.push( p );
		return y;
	}
	@:from @:noCompletion public inline static function fromArrayFloat( a:Array<Float> ):LineString {
		if ( a.length & 1 != 0 )
			throw "Cannot cast Array<Float> to LineString: Array has odd length ("+a.length+")";
		return cast a;
	}
	private inline function get_length():Int return this.length >> 1;
}

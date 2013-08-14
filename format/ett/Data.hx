package format.ett;

import haxe.io.Bytes;

class FileInfo {

	public var newline:String; // NEWLINE-<NL>
	public var encoding:Encoding; // CODING-<ENC>
	public var separator:String; // SEPARATOR-<SEP>
	public var escape:String; // ESCAPE-<QTE>
	public var className:String; // CLASS-<NAME>
	public var fields:Array<Field>;

	public function new() {
		newline = "\n";
		encoding = ISO;
		separator = ",";
		escape = "\"";
		className = "";
		fields = [];
	}

	public function toString() {
		return "Newline: 0x"+Bytes.ofString( newline ).toHex()+"\n"
		+ "Encoding: "+encoding+"\n"
		+ "Separator: "+separator+"\n"
		+ "Escape: "+escape+"\n"
		+ "Class name: "+className+"\n"
		+ "Fields:\n\t"+fields.join( "\n\t" )+"\n";
	}

}

class Field {

	public var name:String;
	public var type:Type;

	public function new( _name, _type ) {
		name = _name;
		type = _type;
	}

	public function toString() {
		return "'"+name+"' : "+type;
	}

}

enum Encoding {
	ISO; // ISO
	UTF8; // UTF-8
}

enum Type {
	// base types
	TNull( of:Type );
	TBool;
	TInt;
	TFloat;
	TString;
	TDate;
	TTimestamp;
	THaxeSerial;
	TTrim( s:Type );
	
	// minimal GIS types
	TGeometry( geomType:Type );
	TPoint;
	TLineString;
	TMultiPolygon;

	// Other
	TUnknown( typeName:String );
}

class Point {
	public var x:Float;
	public var y:Float;
	public function new( _x, _y ) {
		x = _x;
		y = _y;
	}
}

class LineString {
	public var point:Array<Point>;
	public function new( _point ) {
		point = _point;
	}
}

class Polygon {
	public var outer:LineString;
	public var inner:Array<LineString>;
	public function new( _outer, _inner ) {
		outer = _outer;
		inner = _inner;
	}
}

class MultiPolygon {
	public var polygon:Array<Polygon>;
}

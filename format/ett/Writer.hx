package format.ett;

import format.ett.Data;
import format.ett.Geometry;
import format.csv.Tools;

typedef Writer = ETTWriter;

class ETTWriter {

	private var out:haxe.io.Output;
	private var info:FileInfo;
	private var escaper:Escaper;

	public function new( fileInfo:FileInfo ) {
		info = fileInfo.copy();
		escaper = new Escaper( fileInfo.encoding == UTF8, fileInfo.newline, fileInfo.separator, fileInfo.escape );
	}

	public function prepare( output:haxe.io.Output ) {
		out = output;
		writeHeader();
	}

	public function write( d:Dynamic ) {
		if ( out == null )
			throw "No file ready, you must call Writer::prepare before writing any data";
		var first = true;
		var s = new StringBuf();
		for ( f in info.fields ) {
			if ( !first )
				s.add( info.separator );
			else
				first = false;
			s.add( escape( writeData( d, f.name, f.type ) ) );
		}
		s.add( info.newline );
		out.writeString( s.toString() );
	}

	public function close() {
		if ( out != null ) {
			out.close();
			out = null;
		}
	}

	private function writeHeader() {
		var s = new StringBuf();

		s.add( "NEWLINE-" );
		s.add( info.newline );

		s.add( "CODING-" );
		switch ( info.encoding ) {
		case UTF8: s.add( "UTF-8" );
		case ISO: s.add( "ISO" );
		}
		s.add( info.newline );

		s.add( "SEPARATOR-" );
		s.add( info.separator );
		s.add( info.newline );

		s.add( "ESCAPE-" );
		s.add( info.escape );
		s.add( info.newline );

		s.add( "CLASS-" );
		s.add( info.className );
		s.add( info.newline );

		var first = true;
		for ( f in info.fields ) {
			if ( !first )
				s.add( info.separator );
			else
				first = false;
			s.add( escape( writeType( f.type ) ) );
		}
		s.add( info.newline );

		first = true;
		for ( f in info.fields ) {
			if ( !first )
				s.add( info.separator );
			else
				first = false;
			s.add( escape( f.name ) );
		}
		s.add( info.newline );

		out.writeString( s.toString() );
	}

	private function writeType( t:Type ):String {
		return switch ( t ) {
		case TNull( t ): "Null<"+writeType( t )+">";
		case TBool: "Bool";
		case TInt: "Int";
		case TFloat: "Float";
		case TString: "String";
		case TDate: "Date";
		case TTimestamp: "Timestamp";
		case THaxeSerial: "HaxeSerial";
		case TTrim( t ): "Trim<"+writeType( t )+">";

		case TGeometry( t ): "Geometry<"+writeType( t )+">";
		case TPoint: "Point";
		case TLineString: "LineString";
		// case TMultiPolygon: "MultiPolygon";

		case all: throw all;
		};
	}

	private inline function writeData( d:Dynamic, fname:String, ftype:Type, ?nullable=false ):String {
		return switch ( ftype ) {
		case TNull( t ):
			writeData( d, fname, t, true );
		case TBool:
			var fdata = Reflect.field( d, fname );
			if ( fdata != null )
				if ( Std.is( fdata, Bool ) )
					Std.string( fdata );
				else
					throw "Wrong type for field "+fname+" : "+ftype;
			else if ( !nullable )
				throw "Missing field "+fname;
			else
				"";
		case TInt:
			var fdata = Reflect.field( d, fname );
			if ( fdata != null )
				if ( Std.is( fdata, Int ) )
					Std.string( fdata );
				else
					throw "Wrong type for field "+fname+" : "+ftype;
			else if ( !nullable )
				throw "Missing field "+fname;
			else
				"";
		case TFloat:
			var fdata = Reflect.field( d, fname );
			if ( fdata != null )
				if ( Std.is( fdata, Float ) )
					Std.string( fdata );
				else
					throw "Wrong type for field "+fname+" : "+ftype;
			else if ( !nullable )
				throw "Missing field "+fname;
			else
				"";
		case TString:
			var fdata = Reflect.field( d, fname );
			if ( fdata != null )
				if ( Std.is( fdata, String ) )
					fdata;
				else
					throw "Wrong type for field "+fname+" : "+ftype;
			else if ( !nullable )
				throw "Missing field "+fname;
			else
				"";
		case TDate:
			var fdata = Reflect.field( d, fname );
			if ( fdata != null )
				if ( Std.is( fdata, Date ) )
					Std.string( fdata );
				else
					throw "Wrong type for field "+fname+" : "+ftype;
			else if ( !nullable )
				throw "Missing field "+fname;
			else
				"";
		case TTimestamp:
			var fdata:Dynamic = Reflect.hasField( d, fname ) ? Reflect.field( d, fname ) : null;
			if ( fdata != null ) {
				if ( Std.is( fdata, Date ) )
					Std.string( fdata.getTime() );
				else if ( Std.is( fdata, Float ) )
					Std.string( fdata );
				else
					throw "Wrong type for field "+fname+" : "+ftype;
			}
			else if ( !nullable )
				throw "Missing field "+fname;
			else
				"";
		case THaxeSerial:
			var fdata = Reflect.field( d, fname );
			if ( fdata != null )
				haxe.Serializer.run( fdata );
			else if ( !nullable )
				throw "Missing field "+fname;
			else
				"";
		case TTrim( TString ):
			writeData( d, fname, TString, nullable );
		case TGeometry( TPoint ):
			var fdata = Reflect.field( d, fname );
			if ( fdata != null )
				if ( Std.is( fdata, Point ) )
					fdata.rawString();
				else
					throw "Wrong type for field "+fname+" : "+ftype;
			else if ( !nullable )
				throw "Missing field "+fname;
			else
				"";
		case TGeometry( TLineString ):
			var fdata = Reflect.field( d, fname );
			if ( fdata != null )
				if ( Std.is( fdata, LineString ) )
					fdata.rawString();
				else
					throw "Wrong type for field "+fname+" : "+ftype;
			else if ( !nullable )
				throw "Missing field "+fname;
			else
				"";
		// case TGeometry( TMultiPolygon ):
		case all: throw all;
		};
	}

	private inline function escape( s:String ):String {
		return escaper.escape( s );
	}

}

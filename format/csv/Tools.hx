package format.csv;

import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import haxe.io.Eof;
import haxe.io.Input;
import haxe.io.StringInput;

import format.csv.Error;
import format.csv.Tools.*;

typedef Char = Int;

class Tools {

	public static function readChar( i:Input, utf8:Bool ):Char {
		if ( utf8 ) {

			var char:Int = -1;
			try {
				char = readUtf8Start( i );
			}
			catch ( e:CSVUtf8Error ) { // format.csv.Error.CSVUtf8Error
				return 0xefbfbd; // �
			}

			if ( char & 0x80 == 0 ) // single byte char
				return char;
			else {

				try {

					if ( char & 0xe0 == 0xc0 ) // 2 byte char
						return char
						       << 8 | readUtf8Continuation( i );
					else if ( char & 0xf0 == 0xe0 ) // 3 byte char
						return ( char << 8 | readUtf8Continuation( i ) )
						       << 8 | readUtf8Continuation( i );
					else if ( char & 0xf8 == 0xf0 ) // 4 byte char
						return ( ( char << 8 | readUtf8Continuation( i ) )
						         << 8 | readUtf8Continuation( i ) )
						       << 8 | readUtf8Continuation( i );
					else
						throw BadStartByte( char );

				}
				catch ( e:CSVUtf8Error ) { // format.csv.Error.CSVUtf8Error
					return 0xefbfbd; // �
				}
				catch ( e:Eof ) {
					return 0xefbfbd; // �
				}

			}

		}
		else
			return i.readByte();
	}

	public static inline function readAllChars( i:Input, utf8:Bool ):Array<Char> {
		var y = [];
		try {
			while ( true )
				y.push( readChar( i, utf8 ) );
		}
		catch ( eof:Eof ) { }
		return y;
	}

	// adds a character (in any encoding) into a BytesBuffer using the minimum
	// number of bytes possible
	public static inline function addChar( buf:BytesBuffer, c:Char ) {
		if ( c & 0xff000000 != 0 )
			buf.addByte( c >> 24 & 0xff );
		if ( c & 0xff0000 != 0 )
			buf.addByte( c >> 16 & 0xff );
		if ( c & 0xff00 != 0 )
			buf.addByte( c >> 8 & 0xff );
		buf.addByte( c & 0xff );
	}

	public static inline function printChar( char:Char, utf8:Bool ):String {
		if ( char >= 0x20 && char <= 0x7e )
			return String.fromCharCode( char );
		else if ( utf8 && char > 255 ) {
			var b = new BytesBuffer();
			addChar( b, char );
			return b.getBytes().toString();
		}
		else
			return "#" + char;
	}

	public static inline function getBufContents( b:BytesBuffer, utf8:Bool, ?pos=0, ?len=-1 ):String {
		if ( len == -1 ) len = b.length - pos;
		return len > 0 ? b.getBytes().readString( pos, len ) : "";
	}

	private static inline function readUtf8Start( i:Input ):Int {
		var b = i.readByte();
		// trace( [ b, b&0xc0, 0x80 ] );
		if ( b & 0xc0 == 0x80 ) // continuation byte
			throw BadStartByte( b );
		return b;
	}

	private static inline function readUtf8Continuation( i:Input ):Int {
		var b = i.readByte();
		// trace( [ b, b&0x80, 0x80 ] );
		if ( b & 0x80 != 0x80 ) // 10xx xxxx
			throw BadContinuationByte( b );
		return b;
	}

}

class Escaper {
	private var utf8:Bool;
	private var escChar:Char;
	private var ilegals:Array<Char>;

	public function new( _utf8:Bool, newline:String, separator:String, escape:String ) {
		utf8 = _utf8;

		var esc = readAllChars( new StringInput( escape ), utf8 );
		switch ( esc.length ) {
		case 1:
			escChar = esc[0];
		case all:
			throw "Invalid number of chars in escape "+all;
		}
		
		ilegals = [];
		var nl = readAllChars( new StringInput( newline ), utf8 );
		switch ( nl.length ) {
		case 1:
			ilegals = ilegals.concat( nl );
		case 2:
			if ( nl[0] == nl[1] )
				throw "Cannot work with repeated chars on the newline sequence";
			ilegals = ilegals.concat( nl );
		case all:
			throw "Invalid number of chars in newline sequence: "+all;
		}

		var sep = readAllChars( new StringInput( separator ), utf8 );
		switch ( sep.length ) {
		case 1:
			ilegals = ilegals.concat( sep );
		case all:
			throw "Invalid number of chars in separator: "+all;
		}
	}

	public inline function escape( s:String ):String {
		var cs = readAllChars( new StringInput( s ), utf8 );
		var o = new BytesBuffer();
		var escaped = false;
		addChar( o, escChar );
		for ( c in cs ) {
			if ( c == escChar ) {
				escaped = true;
				addChar( o, c );
			}
			else if ( !escaped && charIn( c, ilegals ) ) {
				escaped = true;
			}
			addChar( o, c );
		}
		if ( escaped ) {
			addChar( o, escChar );
			return getBufContents( o, utf8 );
		}
		else {
			return getBufContents( o, utf8, 1 );
		}
	}

	private static inline function charIn( c:Char, chars:Array<Char> ):Bool {
		var y = false;
		for ( _c in chars )
			if ( _c == c ) {
				y = true;
				break;
			}
		return y;
	}

}

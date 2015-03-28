package elebeta.format.oldcsv;

import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import haxe.io.Eof;
import haxe.io.Input;
import haxe.io.StringInput;

import elebeta.format.oldcsv.Error;
import elebeta.format.oldcsv.Tools.*;

typedef Byte = Int; // byte storage
typedef Char = Int; // actual bytes of a char in a single integer (up to 4 bytes)
typedef CharCode = Int; // Unicode char code

class Tools {

	// char tools -------------------------------------------------------------------------------------------------------

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


	// char code tools --------------------------------------------------------------------------------------------------

	// code point from binary representation (Char) in ASCII or UTF-8
	// char must have already been validated
	public static function charCode( char:Char, utf8:Bool ):CharCode {
		if ( utf8 ) {
			return ((char>>6)&0xFC0000) | ((char>>4)&0x3F000) | ((char>>2)&0xFC0) | (char&0x3F);
		}
		else {
			return char;
		}
	}

	// binary representation (Char) of any Unicode code point (up to U+10FFFF) in ASCII or UTF-8
	// all code points above 0xFF became "?" (so this actually lossly converts the code point to Latin-1)
	public static function char( code:CharCode, utf8:Bool ):Char {
		var char = 0;
		if( code <= 0x7F ) {
			char = code;
		}
		else if ( !utf8 ) {
			char = iso( code );
		}
		else if( code <= 0x7FF ) {
			char = (( 0xC0 | (code>>6) ) << 8) | ( 0x80 | (code&63) );
		}
		else if( code <= 0xFFFF ) {
			char = (( 0xE0 | (code>>12) ) << 16) | (( 0x80 | ((code>>6)&63) ) << 8) | ( 0x80 | (code&63) );
		}
		else {
			char = (( 0xF0 | (code>>18) ) << 24) | (( 0x80 | ((code>>12)&63) ) << 16)
			| (( 0x80 | ((code>>6)&63) ) << 8) | ( 0x80 | (code&63) );
		}
		return char;
	}

	// maps all code points to Latin-1, replacing everything else by "?"
	public inline static function iso( code:CharCode ):CharCode {
		return code <= 0xFF ? code : "?".code;
	}
	public inline static function isoChar( char:Char ):Char {
		return iso( char );
	}


	// other tools ------------------------------------------------------------------------------------------------------

	public static inline function getBufContents( b:BytesBuffer, utf8:Bool, ?pos=0, ?len=-1 ):String {
		var bytes = b.getBytes();
		if ( len == -1 ) len = bytes.length - pos;
		#if ( neko || cpp )
		return len > 0 ? bytes.getString( pos, len ) : "";
		#else
		if ( len == 0 ) {
			return "";
		}
		else if ( utf8 ) {
			return len > 0 ? bytes.getString( pos, len ) : "";
		}
		else {
			var sbuf = new StringBuf();
			for ( i in pos...(pos+len) ) {
				sbuf.addChar( bytes.get( i ) );
			}
			return sbuf.toString();
		}
		#end
	}


	// helpers ----------------------------------------------------------------------------------------------------------

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
		#if ( neko || cpp )
		utf8 = _utf8;
		#else
		utf8 = true;
		#end

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

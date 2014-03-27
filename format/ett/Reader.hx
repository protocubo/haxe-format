package format.ett;

import haxe.io.*;
import haxe.Unserializer;
import StringTools.trim;
import Type.createEmptyInstance;

import format.csv.Reader in CSVReader;

import format.ett.Data;
import format.ett.Error;
import format.ett.Geometry;

typedef Reader = ETTReader;

class ETTReader {

	public var info:FileInfo;
	var csvReader:CSVReader;

	var context:Int;

	public function new( _input:Input ) {
		readFileInfo( _input );
	}

	/* 
	 * Reads the next record in the stream.
	 * Returns a Dynamic or an instance of [cl].
	 * Observations:
	 *  - [cl] must be a class and its fields will be set with the reflection
	 *    API.
	 *  - [cl] instance will be created the the Type.createEmptyInstance
	 *    function. Therefore, its constructor wont be called.
	 *  - What happens when setting a field not defined in [cl] depends on the
	 *    behavior of the Reflection class on the selected target.
	 */
	public function readRecord():Dynamic {
		data = csvReader.readRecord( data );
		if ( data.length != info.fields.length )
			throw GenericError( 'Expected #fields = ${info.fields.length} but was ${data.length}' );
		var object:Dynamic = cast {};
		for ( i in 0...info.fields.length ) {
			context = i;
			Reflect.setField( object, info.fields[i].name, parseData( data[i], info.fields[i].type ) );
		}
		return object;
	}

	/* 
	 * Fast version of readRecord, that only changes the received [object]
	 */
	@:generic
	public function fastReadRecord<T>( object:T ):T {
		data = csvReader.readRecord( data );
		if ( data.length != info.fields.length )
			throw GenericError( 'Expected #fields = ${info.fields.length} but was ${data.length}' );
		for ( i in 0...info.fields.length ) {
			context = i;
			Reflect.setField( object, info.fields[i].name, parseData( data[i], info.fields[i].type ) );
		}
		return object;
	}

	private var data:Array<String>; // data array used for faster CSV parsing

	public function close() {
		csvReader.close();
	}

	function readFileInfo( input:Input ):Void {
		var tinfo = std.Type.createEmptyInstance( FileInfo );
		tinfo.fields = [];

		var b:Null<Bytes> = null;

		b = readUntil( input, "NEWLINE-", BadStart );
		if ( b.length != 0 )
			throw BadStart;

		b = readUntil( input, "CODING-", NoCodingTag );
		if ( b.length == 0 )
			throw NoNewlineData;
		tinfo.newline = b.toString();
		// trace( tinfo );

		b = readUntil( input, tinfo.newline, GenericError( "Missing newline sequence after CODING-<COD>" ) );
		if ( b.length == 0 )
			throw NoCodingData;
		switch ( b.toString() ) {
		case "ISO": tinfo.encoding = ISO;
		case "UTF-8": tinfo.encoding = UTF8;
		case all: throw BadCoding( all );
		}
		// trace( tinfo );

		b = readUntil( input, "SEPARATOR-", NoSeparatorTag );
		if ( b.length != 0 )
			throw GenericError ( "Extra bytes between CODING-<COD><NEWLINE> and SEPARATOR-" );
		b = readUntil( input, tinfo.newline, GenericError( "Missing newline sequence after SEPARATOR-<SEP>" ) );
		if ( b.length == 0 )
			throw NoSeparatorData;
		tinfo.separator = b.toString();
		// trace( tinfo );

		b = readUntil( input, "ESCAPE-", NoEscapeTag );
		if ( b.length != 0 )
			throw GenericError ( "Extra bytes between SEPARATOR-<SEP><NEWLINE> and ESCAPE-" );
		b = readUntil( input, tinfo.newline, GenericError( "Missing newline sequence after ESCAPE-<SEP>" ) );
		if ( b.length == 0 )
			throw NoEscapeData;
		tinfo.escape = b.toString();
		// trace( tinfo );

		b = readUntil( input, "CLASS-", NoClassTag );
		if ( b.length != 0 )
			throw GenericError ( "Extra bytes between ESCAPE-<QTE><NEWLINE> and CLASS-" );
		b = readUntil( input, tinfo.newline, GenericError( "Missing newline sequence after CLASS-<NAME>" ) );
		tinfo.className = b.toString();
		// trace( tinfo );

		var utf8 = switch ( tinfo.encoding ) {
		case UTF8: true;
		case all: false;
		};
		csvReader = new CSVReader( input, tinfo.newline, tinfo.separator, tinfo.escape, utf8 );

		var types = csvReader.readRecord().map( trim );
		var columns = csvReader.readRecord().map( trim );

		if ( types.length != columns.length )
			throw GenericError( "Number of types different from number of columns" );

		for ( i in 0...types.length ) {
			if ( columns[i].length == 0 )
				throw EmptyColumnName( i+1 );
			if ( types[i].length == 0 )
				throw EmptyColumnType( i+1 );
			var type = validateType( parseType( types[i] ) );
			tinfo.fields.push( new Field( columns[i], type ) );
			// trace( tinfo );
		}

		info = new FileInfo( tinfo.newline, tinfo.encoding, tinfo.separator
		, tinfo.escape, tinfo.className, tinfo.fields );
	}

	function readUntil( input:Input, k:String, exception:ETTReaderError ):Bytes {
		var kb = Bytes.ofString( k );
		var buf = new BytesBuffer();
		var i:Int;
		var b:Int;
		while ( true ) {
			i = 0;
			while ( i < kb.length ) {
				try {
					b = input.readByte();
				}
				catch ( e:Eof ) {
					throw exception;
				}
				buf.addByte( b );
				if ( b != kb.get( i ) )
					break;
				i++;
			}
			if ( i == kb.length ) {
				var bytes = buf.getBytes();
				var bufLen = bytes.length;
				return bytes.sub( 0, bufLen - kb.length );
			}
		}
		return null;
	}

	/* 
	 * Recursively parses a type definition.
	 * Returns TUnknown( typeDef ) if the type is unknown.
	 */
	function parseType( typeDef:String ):Type {
		var nullable = ~/^Null<(.+)>$/;
		if ( nullable.match( typeDef ) ) {
			return TNull( parseType( nullable.matched( 1 ) ) );
		}

		var trimmable = ~/^Trim<(.+)>$/;
		if ( trimmable.match( typeDef ) ) {
			return TTrim( parseType( trimmable.matched( 1 ) ) );
		}

		var geometry = ~/^Geometry<(.+)>$/;
		if ( geometry.match( typeDef ) ) {
			return TGeometry( parseType( geometry.matched( 1 ) ) );
		}

		return switch ( typeDef ) {
		case "Bool": TBool;
		case "Int": TInt;
		case "Float": TFloat;
		case "String": TString;
		case "Date": TDate;
		case "Timestamp": TTimestamp;
		case "HaxeSerial": THaxeSerial;
		case "Point": TPoint;
		case "LineString": TLineString;
		// case "MultiPolygon": TMultiPolygon;
		case all: TUnknown( all );
		};
	}
	
	/* 
	 * Recursively validades a type.
	 */
	function validateType( t:Type ):Type {
		return switch ( t ) {
		case TNull( TNull( _ ) ): throw NullOfNull( t );
		case TNull( it ): TNull( validateType( it ) );
		case TTrim( TString ): t;
		case TTrim( TNull( _ ) ): throw TrimOfNull( t );
		case TTrim( _ ): throw InvalidTrim( t );
		case TGeometry( TPoint ), TGeometry( TLineString )/*, TGeometry( TMultiPolygon )*/: t;
		case TGeometry( _ ): throw InvalidGeometry( t );
		case TUnknown( ts ): throw UnknownType( ts );
		case all: t;
		};
	}

	/* 
	 * Parses a field string value [s] using type [t].
	 */
	inline function parseData( s:String, t:Type ):Dynamic
		return _parseData( s, t, false );
	function _parseData( s:String, t:Type, nullable:Bool ):Dynamic {
		return switch ( t ) {
		case TNull( t ):

			_parseData( s, t, true );

		case TBool:

			switch ( trim( s ) ) {
			case "true":
				true;
			case "false":
				false;
			case "":
				if ( nullable ) null else throw NotNullable( info.fields[context] );
			case _:
				throw InvalidBool( s, info.fields[context] );
			};

		case TInt:

			s = trim( s );
			if ( s.length != 0 ) {
				#if ETT_UNSAFE
				encaps( Std.parseInt, s );
				#else
				parseInt( s );
				#end
			}
			else if ( nullable )
				null;
			else
				throw NotNullable( info.fields[context] );

		case TFloat:

			s = trim( s );
			if ( s.length != 0 )
				#if ETT_UNSAFE
				encaps( Std.parseFloat, s );
				#else
				parseFloat( s );
				#end
			else if ( nullable )
				null;
			else
				throw NotNullable( info.fields[context] );

		case TTrim( TString ):

			s = trim( s );
			_parseData( trim( s ), TString, nullable );

		case TString:

			if ( s.length != 0 )
				s;
			else if ( nullable )
				null;
			else
				throw NotNullable( info.fields[context] );

		case TDate:

			s = trim( s );
			if ( s.length != 0 )
				encaps( Date.fromString, s );
			else if ( nullable )
				null;
			else
				throw NotNullable( info.fields[context] );

		case TTimestamp:

			var tstamp:Null<Float> = _parseData( s, TFloat, nullable );
			if ( tstamp != null )
				encaps( Date.fromTime, tstamp );
			else
				null;

		case THaxeSerial:

			s = trim( s );
			if ( s.length != 0 )
				encaps( Unserializer.run, s );
			else if ( nullable )
				null;
			else
				throw NotNullable( info.fields[context] );

		case TGeometry( g ):

			_parseData( s, g, false );

		case TPoint:

			s = trim( s );
			var split = s.split( " " );
			var data = [];
			for ( part in split ) {
				if ( part.length > 0 )
					data.push( _parseData( part, TFloat, false ) );
			}
			if ( data.length != 2 )
				throw GenericTypingError( "Cannot parse TGeometry(TPoint) "+s, info.fields[context] );
			new Point( data[0], data[1] );
			
		case TLineString:

			s = trim( s );
			var split = s.split( "," );
			var shape = new LineString();
			for ( part in split ) {
				if ( part.length > 0 )
					shape.push( _parseData( part, TPoint, false ) );
			}
			if ( shape.length < 2 )
				throw GenericTypingError( "Cannot parse TGeometry(TLineString) "+s, info.fields[context] );
			shape;

		// case TMultiPolygon:

		// 	throw CannotParse( info.fields[context] );

		case all:

			throw CannotParse( info.fields[context] );

		};
	}

	inline function parseInt( s:String ) {
		var pos = -1;
		var c = -1;
		var digit = false, hex = false;
		while ( ++pos < s.length ) {
			c = StringTools.fastCodeAt( s, pos );
			switch ( c ) {
			case "-".code, "+".code:
				if ( pos != 0 )
					throw InvalidInt( s, info.fields[context] );
			case "x".code, "X".code:
				if ( pos - 0 != 1 || StringTools.fastCodeAt( s, pos -1 ) != "0".code )
					throw InvalidInt( s, info.fields[context] );
				digit = false;
				hex = true;
			case c if ( c >= "0".code && c <= "9".code ):
				digit = true;
			case c if ( ( c >= "a".code && c <= "f".code ) || ( c >= "A".code && c <= "F".code ) ):
				if ( !hex )
					throw InvalidInt( s, info.fields[context] );
				digit = true;
			case all:
				throw InvalidInt( s, info.fields[context] );
			}
		}
		if ( !digit )
			throw InvalidInt( s, info.fields[context] );
		else
			return Std.parseInt( s );
	}

	inline function parseFloat( s:String ) {
		var pos = -1;
		var c = -1;
		var digit = false;
		var le = false;
		while ( ++pos < s.length ) {
			c = StringTools.fastCodeAt( s, pos );
			switch ( c ) {
			case "-".code, "+".code:
				if ( pos != 0 && !le )
					throw InvalidFloat( s, info.fields[context] );
				le = false;
			case "e".code, "E".code:
				if ( !digit )
					throw InvalidFloat( s, info.fields[context] );
				le = true;
			case ".".code:
				// nothing
			case c if ( c >= "0".code && c <= "9".code ):
				digit = true;
			case all:
				throw InvalidFloat( s, info.fields[context] );
			}
		}
		if ( !digit )
			throw InvalidFloat( s, info.fields[context] );
		else
			return Std.parseFloat( s );
	}

	@:generic
	inline function encaps<T>( f:T->Dynamic, s:T ):Dynamic {
		try {
			return f( s );
		}
		catch ( e:Dynamic ) {
			throw GenericTypingError( e, info.fields[context] );
		}
	}

}

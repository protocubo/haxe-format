package format.ett;

import haxe.io.*;

import format.csv.Reader in CSVReader;

import format.ett.Data;
import format.ett.Error;

import haxe.Unserializer;
import StringTools.trim;

class Reader {

	public var info:FileInfo;
	var csvReader:CSVReader;

	public function new( _input:Input ) {

		readFileInfo( _input );
		// trace( "\n"+info );

	}

	function readFileInfo( input:Input ):Void {
		info = new FileInfo();

		var b:Null<Bytes> = null;

		b = readUntil( input, "NEWLINE-", BadStart );
		if ( b.length != 0 )
			throw BadStart;

		b = readUntil( input, "CODING-", NoCodingTag );
		if ( b.length == 0 )
			throw NoNewlineData;
		info.newline = b.toString();
		// trace( info );

		b = readUntil( input, info.newline, GenericError( "Missing newline sequence after CODING-<COD>" ) );
		if ( b.length == 0 )
			throw NoCodingData;
		switch ( b.toString() ) {
		case "ISO": info.encoding = ISO;
		case "UTF-8": info.encoding = UTF8;
		case all: throw BadCoding( all );
		}
		// trace( info );

		b = readUntil( input, "SEPARATOR-", NoSeparatorTag );
		if ( b.length != 0 )
			throw GenericError ( "Extra bytes between CODING-<COD><NEWLINE> and SEPARATOR-" );
		b = readUntil( input, info.newline, GenericError( "Missing newline sequence after SEPARATOR-<SEP>" ) );
		if ( b.length == 0 )
			throw NoSeparatorData;
		info.separator = b.toString();
		// trace( info );

		b = readUntil( input, "ESCAPE-", NoEscapeTag );
		if ( b.length != 0 )
			throw GenericError ( "Extra bytes between SEPARATOR-<SEP><NEWLINE> and ESCAPE-" );
		b = readUntil( input, info.newline, GenericError( "Missing newline sequence after ESCAPE-<SEP>" ) );
		if ( b.length == 0 )
			throw NoEscapeData;
		info.escape = b.toString();
		// trace( info );

		b = readUntil( input, "CLASS-", NoClassTag );
		if ( b.length != 0 )
			throw GenericError ( "Extra bytes between ESCAPE-<QTE><NEWLINE> and CLASS-" );
		b = readUntil( input, info.newline, GenericError( "Missing newline sequence after CLASS-<NAME>" ) );
		info.className = b.toString();
		// trace( info );

		var utf8 = switch ( info.encoding ) {
		case UTF8: true;
		case all: false;
		};
		csvReader = new CSVReader( input, info.newline, info.separator, info.escape, utf8 );

		var types = csvReader.readRecord().map( trim );
		var columns = csvReader.readRecord().map( trim );

		if ( types.length != columns.length )
			throw GenericError( "Number of types different from number of columns" );

		for ( i in 0...types.length ) {
			if ( columns[i].length == 0 )
				throw GenericError( "Column name cannot be null" );
			if ( types[i].length == 0 )
				throw GenericError( "Type cannot be null" );
			var type = parseType( types[i] );
			validateType( type );
			info.fields.push( new Field( columns[i], type ) );
			// trace( info );
		}
	}

	public function readRecord():Dynamic {
		var data = csvReader.readRecord();
		if ( data.length != info.fields.length )
			throw GenericError( 'Expected #fields = ${info.fields.length} but was ${data.length}' );
		var r:Dynamic = cast {};
		for ( i in 0...info.fields.length ) {
			Reflect.setField( r, info.fields[i].name, parseData( data[i], info.fields[i].type ) );
		}
		return r;
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
			if ( i == kb.length )
				return buf.getBytes().sub( 0, buf.length - kb.length );
		}
		return null;
	}

	function parseType( s:String ):Type {
		var nullable = ~/^Null<(.+)>$/;
		if ( nullable.match( s ) ) {
			return TNull( parseType( nullable.matched( 1 ) ) );
		}

		var trimmable = ~/^Trim<(.+)>$/;
		if ( trimmable.match( s ) ) {
			return TTrim( parseType( trimmable.matched( 1 ) ) );
		}

		return switch ( s ) {
		case "Bool": TBool;
		case "Int": TInt;
		case "Float": TFloat;
		case "String": TString;
		case "Date": TDate;
		case "Timestamp": TTimestamp;
		case "HaxeSerial": THaxeSerial;
		case all: throw GenericError( "Unknown type "+all );
		};
	}
	
	function validateType( t:Type ):Void {
		switch ( t ) {
		case TNull( TNull( _ ) ): throw GenericError( "Null<Null<... not allowed" );
		case TNull( _ ): // ok
		case TTrim( TString ): // ok
		case TTrim( TNull( _ ) ): throw GenericError( "Trim<Null<... not allowed" );
		case TTrim( _ ): throw GenericError( "Only Trim<String> is allowed" );
		case all: // ok
		}
	}

	function parseData( s:String, t:Type ):Dynamic {
		return switch ( t ) {
		case TNull( t ):
			s.length != 0 ? parseData( s, t ) : null;
		case TBool:
			switch ( parseString( s, true ) ) {
			case "true": true;
			case "false": false;
			case _: throw GenericError( "Invalid boolean "+s );
			};
		case TInt:
			Std.parseInt( parseString( s, true ) );
		case TFloat:
			Std.parseFloat( parseString( s, true ) );
		case TTrim( TString ):
			parseData( parseString( s, true ), TString );
		case TString:
			parseString( s, false );
		case TDate:
			Date.fromString( parseString( s, true ) );
		case TTimestamp:
			Date.fromTime( parseData( s, TFloat ) );
		case THaxeSerial:
			Unserializer.run( parseString( s, true ) );
		case _:
			throw GenericError( "Cannot read data with type "+t );
		};
	}

	function parseString( s:String, trimmed:Bool ):String {
		if ( trimmed )
			s = trim( s );
		if ( s.length != 0 )
			return s;
		else
			throw GenericError( "Null not allowed for this field" );
	}

}

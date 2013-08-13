package format.csv;

import haxe.io.*;
import format.csv.Error;

class Reader {

	var utf8:Bool;
	var typeTable:CharTypeTable;
	var input:Input;
	
	var state:ReaderState;

	public function new( _input:Input, ?newline="\n", ?separator=",", ?quote="\"", ?_utf8=false ) {

		utf8 = _utf8;
		typeTable = new CharTypeTable();
		input = _input;
		
		state = StartFile;

		var nl = readAllChars( new BytesInput( Bytes.ofString( newline ) ) );
		switch ( nl.length ) {
		case 1:
			typeTable.set( nl[0], NL0_noNL1 );
		case 2:
			if ( nl[0] == nl[1] )
				throw "Cannot work with repeated chars on the newline sequence";
			typeTable.set( nl[0], NL0 );
			typeTable.set( nl[1], NL1 );
		case all:
			throw "Invalid number of chars in newline sequence: "+all;
		}

		var sep = readAllChars( new BytesInput( Bytes.ofString( separator ) ) );
		switch ( sep.length ) {
		case 1:
			typeTable.set( sep[0], SEP );
		case all:
			throw "Invalid number of chars in separator: "+all;
		}

		var qte = readAllChars( new BytesInput( Bytes.ofString( quote ) ) );
		switch ( qte.length ) {
		case 1:
			typeTable.set( qte[0], QTE );
		case all:
			throw "Invalid number of chars in quote "+all;
		}

	}

	public function close():Void {
		input.close();
		input = null;
	}

	public function readRecord():Array<String> {

		if ( input == null )
			throw "No input stream (probably it has already been closed)";

		switch ( state ) {
		case EOF: throw new Eof();
		case all: // nothing to do
		}

		var record:Array<String> = [];
		var field:BytesBuffer = null;
		var cur:Char = 0;
		var pre:Char = 0;
		var curType:CharType = EOF;
		while ( true ) {

			pre = cur;
			try {
				cur = readChar( input );
				curType = typeTable.get( cur );
			}
			catch ( eof:Eof ) {
				curType = EOF;
			}
			// trace( [ printChar( cur ), curType, state ] );
			
			switch ( curType ) {
			case NL0:

				switch ( state ) {
				case StartFile, Newline, Separator, Unquoted, QuotedPostQuote:
					state = NewlineWaitForNL1;
				case NewlineWaitForNL1:
					state = Unquoted;
					// field may have not been prepared yet
					if ( field == null )
						field = new BytesBuffer();
					// add the NL0-NL0 sequence to the current field
					addChar( field, pre );
					addChar( field, cur );
				case Quoted:
					// state = Quoted;
					addChar( field, cur ); // field prepared uppon entry to the Quoted state
				case EOF:
					throw "Cannot reach this point";
				}

			case NL0_noNL1:
			
				switch ( state ) {
				case StartFile, Newline, Separator, Unquoted, QuotedPostQuote:
					state = Newline;
					// if there was a field, add it to the record
					if ( field != null )
						record.push( getBufContets( field ) );
					// a record is ready to be returned
					break;
				case NewlineWaitForNL1:
					throw "Cannot reach this point";
				case Quoted:
					// state = Quoted;
					addChar( field, cur ); // field prepared uppon entry to the Quoted state
				case EOF:
					throw "Cannot reach this point";
				}

			case NL1:

				switch ( state ) {
				case StartFile, Newline, Separator, Unquoted:
					state = Unquoted;
					// field may have not been prepared yet
					if ( field == null )
						field = new BytesBuffer();
					// add the NL1 to the current field
					addChar( field, cur );
				case NewlineWaitForNL1:
					state = Newline;
					// if there was a field, add it to the record
					if ( field != null )
						record.push( getBufContets( field ) );
					// a record is ready to be returned
					break;
				case Quoted:
					// state = Quoted;
					addChar( field, cur ); // field prepared uppon entry to the Quoted state
				case QuotedPostQuote:
					throw 'Invalid char \'${printChar( cur )}\' after QTE in quoted field';
				case EOF:
					throw "Cannot reach this point";
				}

			case SEP:

				switch ( state ) {
				case StartFile, Newline, Separator, Unquoted, QuotedPostQuote:
					state = Separator;
					// field may have not been prepared yet
					if ( field == null )
						field = new BytesBuffer();
					// save the current field
					record.push( getBufContets( field ) );
					// prepare another field, a separator implies that there is
					// something else to come
					field = new BytesBuffer();
				case NewlineWaitForNL1:
					state = Unquoted;
					if ( field == null ) // field may have not been prepared yet
						field = new BytesBuffer();
					// add the NL0-SEP sequence to the current field
					addChar( field, pre );
					addChar( field, cur );
				case Quoted:
					// state = Quoted;
					addChar( field, cur ); // field prepared uppon entry to the Quoted state
				case EOF:
					throw "Cannot reach this point";
				}

			case QTE:

				switch ( state ) {
				case StartFile, Newline, Separator:
					state = Quoted;
					// prepare the quoted field
					field = new BytesBuffer();
				case NewlineWaitForNL1:
					state = Unquoted;
					if ( field == null ) // field may have not been prepared yet
						field = new BytesBuffer();
					// add the NL0-QTE sequence to the current field
					addChar( field, pre );
					addChar( field, cur );
				case Unquoted:
					// state = Unquoted;
					// add the QTE to the current field
					addChar( field, cur ); // field prepared uppon entry to the Unquoted state
				case Quoted:
					state = QuotedPostQuote;
				case QuotedPostQuote:
					state = Quoted;
					// add _one_ QTE to the current field
					addChar( field, cur ); // field prepared before entry to the QuotedPostQuote state
				case EOF:
					throw "Cannot reach this point";
				}

			case EOF:

				switch ( state ) {
				case NewlineWaitForNL1:
					state = EOF;
					throw "EOF resulted in incomplete newline sequence";
				case Newline:
					state = EOF;
					// proper end of file
					throw new Eof();
					// break;
				case all:
					state = EOF;
					// acceptable end of file
					if ( field != null )
						record.push( getBufContets( field ) );
					// a record is ready to be returned
					break;
				}

			case OTHER:

				switch ( state ) {
				case StartFile, Newline, Separator, Unquoted:
					state = Unquoted;
					// field may have not been prepared yet
					if ( field == null )
						field = new BytesBuffer();
					// add char to the current field
					addChar( field, cur );
				case NewlineWaitForNL1:
					state = Unquoted;
					// field may have not been prepared yet
					if ( field == null )
						field = new BytesBuffer();
					// add the NL0-char sequence to the current field
					addChar( field, pre );
					addChar( field, cur );
				case Quoted:
					// state = Quoted;
					// add char to the current field
					addChar( field, cur ); // field prepared uppon entry to the Quoted state
				case QuotedPostQuote:
					throw 'Invalid char \'${printChar( cur )}\' after QTE in quoted field';
				case EOF:
					throw "Cannot reach this point";
				}

			}

		}

		return record;
	}

	function readChar( i:Input ):Char {
		if ( utf8 ) {

			var char:Int = -1;
			try {
				char = readUtf8Start( i );
			}
			catch ( e:CSVUtf8Error ) { // format.csv.Error.CSVUtf8Error
				return 0xfffd; // �
			}

			if ( char & 0x80 == 0 ) // single byte char
				return char;
			else

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
				return 0xfffd; // �
			}
			catch ( e:Eof ) {
				return 0xfffd; // �
			}

		}
		else
			return i.readByte();
	}

	function readUtf8Start( i:Input ):Int {
		var b = i.readByte();
		// trace( [ b, b&0xc0, 0x80 ] );
		if ( b & 0xc0 == 0x80 ) // continuation byte
			throw BadStartByte( b );
		return b;
	}

	function readUtf8Continuation( i:Input ):Int {
		var b = i.readByte();
		// trace( [ b, b&0x80, 0x80 ] );
		if ( b & 0x80 != 0x80 ) // 10xx xxxx
			throw BadContinuationByte( b );
		return b;
	}

	function readAllChars( i:Input ):Array<Char> {
		var y = [];
		try {
			while ( true )
				y.push( readChar( i ) );
		}
		catch ( eof:Eof ) { }
		return y;
	}

	function addChar( buf:BytesBuffer, c:Char ) {
		if ( c & 0xff000000 != 0 )
			buf.addByte( c >> 24 & 0xff );
		if ( c & 0xff0000 != 0 )
			buf.addByte( c >> 16 & 0xff );
		if ( c & 0xff00 != 0 )
			buf.addByte( c >> 8 & 0xff );
		buf.addByte( c & 0xff );
	}

	function printChar( char:Char ):String {
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

	/* 
	 * Introduced to avoid problems with the inconsistent behaviour
	 * for Bytes::toString when Bytes::length == 0.
	 * Issue: https://github.com/HaxeFoundation/haxe/issues/2076
	 */
	inline function getBufContets( b:BytesBuffer ):String {
		#if neko
		return b.getBytes().toString();
		#else
		var bytes = b.getBytes();
		return bytes.length > 0 ? bytes.toString() : "";
		#end
	}

}

#if (!TESTCSV) private #end typedef Char = Int;

#if (!TESTCSV) private #end class CharTypeTable {
	
	var charType:Array<CharTypeKeyVal>;

	public function new() {
		charType = [];
	}

	public function get( char:Char ):CharType {
		for ( x in charType )
			if ( char == x.char )	
				return x.type;
		return OTHER;
	}

	public function set( char:Char, type:CharType ):Void {
		switch ( get( char ) ) {
		case OTHER:
			charType.push( new CharTypeKeyVal( char, type ) );
		case all:
			throw 'Char type $type already registred';
		}
	}

}

#if (!TESTCSV) private #end class CharTypeKeyVal {

	public var char( default, null ):Char;
	public var type( default, null ):CharType;

	public function new( _char:Char, _type:CharType ) {
		char = _char;
		type = _type;
	}

}

#if (!TESTCSV) private #end enum CharType {
	NL0; // only if the newline sequence is NL0NL1
	NL1;
	NL0_noNL1;
	SEP;
	QTE;
	OTHER;
	EOF; // -1
	// NULL;
}

#if (!TESTCSV) private #end enum ReaderState {
	StartFile;
	NewlineWaitForNL1;
	Newline;
	Separator;
	Unquoted;
	Quoted;
	QuotedPostQuote;
	EOF;
}

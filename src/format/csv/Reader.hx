package format.csv;

import haxe.io.*;

class Reader {

	var utf8:Bool;
	var typeTable:CharTypeTable;
	var input:Input;
	
	var state:ReaderState;

	public function new( _input:Input, ?newline="\n", ?separator=",", ?quote="\"", ?_utf8=false ) {

		utf8 = _utf8;
		typeTable = new CharTypeTable( utf8 );
		input = _input;
		
		state = StartFile;

		var nl = readAllChars( new BytesInput( Bytes.ofString( newline ) ) );
		switch ( nl.length ) {
		case 1:
			typeTable.set( nl[0], NL0_noNL1 );
		case 2:
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
		var cur:Char = EOF_CHAR;
		var pre:Char = EOF_CHAR;
		while ( true ) {

			pre = cur;
			try {
				cur = readChar( input );
			}
			catch ( eof:Eof ) {
				cur = EOF_CHAR;
			}
			// trace( [ printChar( cur ), typeTable.get( cur ), state ] );
			
			switch ( typeTable.get( cur ) ) {
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
						record.push( field.getBytes().toString() );
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
						record.push( field.getBytes().toString() );
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
					record.push( field.getBytes().toString() );
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
						record.push( field.getBytes().toString() );
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
			var b = i.readByte();
			if ( b > 127 )
				b = b << 8 | i.readByte();
			return b;
		}
		else
			return i.readByte();
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
		if ( c > 255 ) {
			buf.addByte( c >> 8 );
			buf.addByte( c & 0xff );
		}
		else
			buf.addByte( c );
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

	static inline var EOF_CHAR = -1;

}

#if (!TESTCSV) private #end typedef Char = Int;

#if (!TESTCSV) private #end class CharTypeTable {
	
	var charType:Array<CharType>;
	var max:Int;

	public function new( utf8 ) {
		max = utf8 ? 0xffff : 0xff;
		charType = [];
		charType[max+1] = EOF;
	}

	public function get( char:Char ):CharType {
		if ( char < 0 )
			return EOF;
		else if ( char <= max ) {
			var t = charType[char];
			return t != null ? t : OTHER;
		}
		else
			return OTHER;
	}

	public function set( char:Char, type:CharType ):Void {
		if ( char < 0 || char > max )
			throw 'Cannot set char type for char $char';
		charType[char] = type;
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

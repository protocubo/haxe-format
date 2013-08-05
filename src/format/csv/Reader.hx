package format.csv;

import haxe.io.Eof;
import haxe.io.Input;

class Reader {

	var input:Input;
	var charType:Array<CharType>;
	var state:State;
	var cur:Char;
	var pre:Char;

	public function new( i:Input, ?newline="\n", ?separator=",", ?quote="\"" ) {

		prepareCharTypes();
		input = i;
		state = StartFile;

		switch ( newline.length ) {
		case 1:
			setCharType( newline.charCodeAt( 0 ), NL0_noNL1 );
		case 2:
			setCharType( newline.charCodeAt( 0 ), NL0 );
			setCharType( newline.charCodeAt( 1 ), NL1 );
		case all:
			throw "Invalid number of chars in newline sequence: "+all;
		}

		switch ( separator.length ) {
		case 1:
			setCharType( separator.charCodeAt( 0 ), SEP );
		case all:
			throw "Invalid number of chars in separator: "+all;
		}

		switch ( quote.length ) {
		case 1:
			setCharType( quote.charCodeAt( 0 ), QTE );
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
		var field:StringBuf = null;
		while ( true ) {

			pre = cur;
			try {
				cur = readChar();
				// trace( renderChar( cur ) );
				// trace( getCharType( cur ) );
			}
			catch ( eof:Eof ) {
				cur = -1;
			}

			
			switch ( getCharType( cur ) ) {
			case NL0:

				switch ( state ) {
				case StartFile, Newline, Separator, Unquoted, QuotedPostQuote:
					state = NewlineWaitForNL1;
				case NewlineWaitForNL1:
					state = Unquoted;
					// field may have not been prepared yet
					if ( field == null )
						field = new StringBuf();
					// add the NL0-NL0 sequence to the current field
					field.addChar( pre );
					field.addChar( cur );
				case Quoted:
					// state = Quoted;
					field.addChar( cur ); // field prepared uppon entry to the Quoted state
				case EOF:
					throw "Cannot reach this point";
				}

			case NL0_noNL1:
			
				switch ( state ) {
				case StartFile, Newline, Separator, Unquoted, QuotedPostQuote:
					state = Newline;
					// if there was a field, add it to the record
					if ( field != null )
						record.push( field.toString() );
					// a record is ready to be returned
					break;
				case NewlineWaitForNL1:
					throw "Cannot reach this point";
				case Quoted:
					// state = Quoted;
					field.addChar( cur ); // field prepared uppon entry to the Quoted state
				case EOF:
					throw "Cannot reach this point";
				}

			case NL1:

				switch ( state ) {
				case StartFile, Newline, Separator, Unquoted:
					state = Unquoted;
					// field may have not been prepared yet
					if ( field == null )
						field = new StringBuf();
					// add the NL1 to the current field
					field.addChar( cur );
				case NewlineWaitForNL1:
					state = Newline;
					// if there was a field, add it to the record
					if ( field != null )
						record.push( field.toString() );
					// a record is ready to be returned
					break;
				case Quoted:
					// state = Quoted;
					field.addChar( cur ); // field prepared uppon entry to the Quoted state
				case QuotedPostQuote:
					throw 'Invalid char \'${renderChar( cur )}\' after QTE in quoted field';
				case EOF:
					throw "Cannot reach this point";
				}

			case SEP:

				switch ( state ) {
				case StartFile, Newline, Separator, Unquoted, QuotedPostQuote:
					state = Separator;
					// field may have not been prepared yet
					if ( field == null )
						field = new StringBuf();
					// save the current field
					record.push( field.toString() );
					// prepare another field, a separator implies that there is
					// something else to come
					field = new StringBuf();
				case NewlineWaitForNL1:
					state = Unquoted;
					if ( field == null ) // field may have not been prepared yet
						field = new StringBuf();
					// add the NL0-SEP sequence to the current field
					field.addChar( pre );
					field.addChar( cur );
				case Quoted:
					// state = Quoted;
					field.addChar( cur ); // field prepared uppon entry to the Quoted state
				case EOF:
					throw "Cannot reach this point";
				}

			case QTE:

				switch ( state ) {
				case StartFile, Newline, Separator:
					state = Quoted;
					// prepare the quoted field
					field = new StringBuf();
				case NewlineWaitForNL1:
					state = Unquoted;
					if ( field == null ) // field may have not been prepared yet
						field = new StringBuf();
					// add the NL0-QTE sequence to the current field
					field.addChar( pre );
					field.addChar( cur );
				case Unquoted:
					// state = Unquoted;
					// add the QTE to the current field
					field.addChar( cur ); // field prepared uppon entry to the Unquoted state
				case Quoted:
					state = QuotedPostQuote;
				case QuotedPostQuote:
					state = Quoted;
					// add _one_ QTE to the current field
					field.addChar( cur ); // field prepared before entry to the QuotedPostQuote state
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
						record.push( field.toString() );
					// a record is ready to be returned
					break;
				}

			case OTHER:

				switch ( state ) {
				case StartFile, Newline, Separator, Unquoted:
					state = Unquoted;
					// field may have not been prepared yet
					if ( field == null )
						field = new StringBuf();
					// add char to the current field
					field.addChar( cur );
				case NewlineWaitForNL1:
					state = Unquoted;
					// field may have not been prepared yet
					if ( field == null )
						field = new StringBuf();
					// add the NL0-char sequence to the current field
					field.addChar( pre );
					field.addChar( cur );
				case Quoted:
					// state = Quoted;
					// add char to the current field
					field.addChar( cur ); // field prepared uppon entry to the Quoted state
				case QuotedPostQuote:
					throw 'Invalid char \'${renderChar( cur )}\' after QTE in quoted field';
				case EOF:
					throw "Cannot reach this point";
				}

			}

		}

		return record;
	}

	function prepareCharTypes() {
		charType = [];
		for ( i in 0...256 )
			charType[i] = OTHER;
	}

	function readChar():Char {
		return input.readByte();
	}

	function renderChar( char:Char ):String {
		return String.fromCharCode( char );
	}

	function getCharType( char:Char ):CharType {
		// trace( renderChar( char ) );
		return switch ( char ) {
		case x if ( x < 0 ): EOF;
		case x if ( x < 256 ): charType[char];
		case all: OTHER;
		};
	}

	function setCharType( char:Char, type:CharType ):Void {
		switch ( char ) {
		case x if ( x >= 0 &&x < 256 ): charType[char] = type;
		case all: throw 'Cannot set char type for char \'${renderChar( char )}\' ($char)';
		}
	}

}

typedef Char = Int;

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

#if (!TESTCSV) private #end enum State {
	StartFile;
	NewlineWaitForNL1;
	Newline;
	Separator;
	Unquoted;
	Quoted;
	QuotedPostQuote;
	EOF;
}

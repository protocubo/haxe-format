package format.csv;

import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import haxe.io.BytesInput;
import haxe.io.Eof;
import haxe.io.Input;

import format.csv.Error;
import format.csv.ReaderHelpers;
import format.csv.Tools.*;
import format.csv.Tools;

typedef Reader = CSVReader;

class CSVReader {

	var utf8:Bool;
	var typeTable:CharTypeTable;
	var input:Input;
	
	var state:ReaderState;

	public function new( _input:Input, ?newline="\n", ?separator=",", ?quote="\"", ?_utf8=false ) {

		utf8 = _utf8;
		typeTable = new CharTypeTable();
		input = _input;
		
		state = StartFile;

		var nl = readAllChars( new BytesInput( Bytes.ofString( newline ) ), utf8 );
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

		var sep = readAllChars( new BytesInput( Bytes.ofString( separator ) ), utf8 );
		switch ( sep.length ) {
		case 1:
			typeTable.set( sep[0], SEP );
		case all:
			throw "Invalid number of chars in separator: "+all;
		}

		var qte = readAllChars( new BytesInput( Bytes.ofString( quote ) ), utf8 );
		switch ( qte.length ) {
		case 1:
			typeTable.set( qte[0], QTE );
		case all:
			throw "Invalid number of chars in quote "+all;
		}

	}

	public function close():Void {
		if ( input != null ) {
			input.close();
			input = null;
		}
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
				cur = readChar( input, utf8 );
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
						record.push( getBufContents( field ) );
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
						record.push( getBufContents( field ) );
					// a record is ready to be returned
					break;
				case Quoted:
					// state = Quoted;
					addChar( field, cur ); // field prepared uppon entry to the Quoted state
				case QuotedPostQuote:
					throw 'Invalid char \'${printChar( cur, utf8 )}\' after QTE in quoted field';
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
					record.push( getBufContents( field ) );
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
						record.push( getBufContents( field ) );
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
					throw 'Invalid char \'${printChar( cur, utf8 )}\' after QTE in quoted field';
				case EOF:
					throw "Cannot reach this point";
				}

			}

		}

		return record;
	}

}

package elebeta.format.oldcsv;

import elebeta.format.oldcsv.Tools;

class CharTypeTable {
	
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

class CharTypeKeyVal {

	public var char( default, null ):Char;
	public var type( default, null ):CharType;

	public function new( _char:Char, _type:CharType ) {
		char = _char;
		type = _type;
	}

}

enum CharType {
	NL0; // only if the newline sequence is NL0NL1
	NL1;
	NL0_noNL1;
	SEP;
	QTE;
	OTHER;
	EOF; // -1
	// NULL;
}

enum ReaderState {
	StartFile;
	NewlineWaitForNL1;
	Newline;
	Separator;
	Unquoted;
	Quoted;
	QuotedPostQuote;
	EOF;
}

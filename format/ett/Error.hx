package format.ett;

import format.ett.Data;

enum ETTReaderError {
	
	// Generic error
	GenericError( msg:String );

	// NEWLINE setting errors
	BadStart; // did not start with NEWLINE-
	NoNewlineData;
	
	// CODING setting errors
	NoCodingTag;
	NoCodingData;
	BadCoding( coding:String );
	
	// SEPARATOR setting errors
	NoSeparatorTag;
	NoSeparatorData;
	
	// ESCAPE setting errors
	NoEscapeTag;
	NoEscapeData;
	
	// CLASS setting errors
	NoClassTag;

	// Basic table header errors
	EmptyColumnName( columnNo:Int ); // starting at 1
	EmptyColumnType( columnNo:Int ); // starting at 1

	// Table typing errors
	NullOfNull( t:Type );
	TrimOfNull( t:Type );
	InvalidTrim( t:Type );
	InvalidGeometry( t:Type );
	UnknownType( fieldType:String );

	// Data typing errors
	GenericTypingError( e:Dynamic, field:Field );
	InvalidBool( str:String, field:Field );
	InvalidInt( std:String, field:Field );
	InvalidFloat( std:String, field:Field );
	NotNullable( field:Field );
	CannotParse( field:Field );

}

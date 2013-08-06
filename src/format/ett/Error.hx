package format.ett;

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
}

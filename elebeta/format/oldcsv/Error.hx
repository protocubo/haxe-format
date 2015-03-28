package elebeta.format.oldcsv;

typedef Error = String;

enum CSVUtf8Error {
	BadStartByte( b:Int );
	BadContinuationByte( b:Int );
}

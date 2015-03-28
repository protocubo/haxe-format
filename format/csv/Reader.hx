package format.csv;

private typedef OldReader = format.csv.old.Reader;

@:forward abstract Reader(OldReader) {
	@:deprecated("Lib 'csv' is now recommended for reading CSV files")
	public function new( _input, ?newline="\n", ?separator=",", ?quote="\"", ?_utf8=false ) {
		this = new OldReader(_input, newline, separator, quote, _utf8);
	}
}

typedef CSVReader = Reader;


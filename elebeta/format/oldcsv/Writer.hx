package elebeta.format.oldcsv;

import haxe.io.Output;

import elebeta.format.oldcsv.Tools;

typedef Writer = CSVWriter;

class CSVWriter {

	private var out:Output;
	private var utf8:Bool;
	private var separator:String;
	private var newline:String;
	private var escaper:Escaper;

	public function new( _output:Output, ?_newline="\n", ?_separator=",", ?_quote="\"", ?_utf8=false ) {
		out = _output;
		utf8 = _utf8;
		separator = _separator;
		newline = _newline;
		escaper = new Escaper( utf8, newline, separator, _quote );
	}

	public inline function writeRecord( data:Array<String> ) {
		out.writeString( data.map( escape ).join( separator ) );
		out.writeString( newline );
	}

	public function close() {
		if ( out != null ) {
			out.close();
			out = null;
		}
	}

	private inline function escape( s:String ):String {
		return escaper.escape( s );
	}

}

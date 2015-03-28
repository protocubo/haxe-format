package ;

import haxe.io.*;
import haxe.Timer;

import elebeta.format.oldcsv.Error;
import elebeta.format.oldcsv.Reader;
import elebeta.format.oldcsv.ReaderHelpers;
import elebeta.format.oldcsv.Tools;
import elebeta.format.oldcsv.Writer;

class TestCSVReader extends TestCase {

	function reader( i, nl, sep, qte ) {
		return new Reader( i, nl, sep, qte );
	}

	public function testConstruction() {
		var i = new StringInput( "test string" );

		// good
		var a = reader( i, "N", "S", "Q");
		var b = reader( i, "NL", "S", "Q");

		// bad
		assertAnyException( reader.bind( i,    "",  "S",  "Q") );
		assertAnyException( reader.bind( i,  "NL",   "",  "Q") );
		assertAnyException( reader.bind( i,  "NL", "SX",  "Q") );
		assertAnyException( reader.bind( i,  "NL",  "S",   "") );
		assertAnyException( reader.bind( i,  "NL",  "S", "QX") );

	}

	public function testNewlines() {
		// single char NL
		assertEquals( write( [ [11,12,13], [21,22,23] ] )
			         , read( "11:12:13$21:22:23$", "$", ":", "'" ) );
		// double char NL
		assertEquals( write( [ [11,12,13], [21,22,23] ] )
			         , read( "11:12:13$%21:22:23$%", "$%", ":", "'" ) );
		// now without ending NL
		assertEquals( write( [ [11,12,13], [21,22,23] ] )
			         , read( "11:12:13$21:22:23", "$", ":", "'" ) );
		assertEquals( write( [ [11,12,13], [21,22,23] ] )
			         , read( "11:12:13$%21:22:23", "$%", ":", "'" ) );
		// empty lines
		assertEquals( write( [ [], [11,12,13], [21,22,23], [] ] )
			         , read( "$11:12:13$21:22:23$$", "$", ":", "'" ) );
		assertEquals( write( [ [], [11,12,13], [21,22,23], [] ] )
			         , read( "$%11:12:13$%21:22:23$%$%", "$%", ":", "'" ) );
	}

	public function testQuoting() {
		// unnecessary quote
		assertEquals( write( [ ["11",12,"13"], ["21",22,23] ] )
			         , read( "'11':12:'13'$'21':22:23$", "$", ":", "'" ) );
		// necessary quote
		assertEquals( write( [ ["11:11",12,"13$13"], ["21:21",22,23] ] )
			         , read( "'11:11':12:'13$13'$'21:21':22:23$", "$", ":", "'" ) );
		// quote in quote
		assertEquals( write( [ ["11':'11",12,"'13$13'"], ["'",22,23] ] )
			         , read( "'11'':''11':12:'''13$13'''$'''':22:23$", "$", ":", "'" ) );
		// now with double char NLs
		assertEquals( write( [ ["11",12,"13"], ["21",22,23] ] )
			         , read( "'11':12:'13'$%'21':22:23$%", "$%", ":", "'" ) );
		assertEquals( write( [ ["11:11",12,"13$%13"], ["21:21",22,23] ] )
			         , read( "'11:11':12:'13$%13'$%'21:21':22:23$%", "$%", ":", "'" ) );
		assertEquals( write( [ ["11':'11",12,"'13$%13'"], ["'",22,23] ] )
			         , read( "'11'':''11':12:'''13$%13'''$%'''':22:23$%", "$%", ":", "'" ) );
		// now without ending NL
		assertEquals( write( [ ["11",12,"13"], ["21",22,23] ] )
			         , read( "'11':12:'13'$'21':22:23", "$", ":", "'" ) );
		assertEquals( write( [ ["11:11",12,"13$13"], ["21:21",22,23] ] )
			         , read( "'11:11':12:'13$13'$'21:21':22:23", "$", ":", "'" ) );
		assertEquals( write( [ ["11':'11",12,"'13$13'"], ["'",22,23] ] )
			         , read( "'11'':''11':12:'''13$13'''$'''':22:23", "$", ":", "'" ) );
		assertEquals( write( [ ["11",12,"13"], ["21",22,23] ] )
			         , read( "'11':12:'13'$%'21':22:23", "$%", ":", "'" ) );
		assertEquals( write( [ ["11:11",12,"13$%13"], ["21:21",22,23] ] )
			         , read( "'11:11':12:'13$%13'$%'21:21':22:23", "$%", ":", "'" ) );
		assertEquals( write( [ ["11':'11",12,"'13$%13'"], ["'",22,23] ] )
			         , read( "'11'':''11':12:'''13$%13'''$%'''':22:23", "$%", ":", "'" ) );
	}

	public function testEmptyFields() {
		assertEquals( write( [ [ 1, "", 3 ], [ "", 2, "" ] ] )
		            , read( "1,,3NL,2,NL", "NL", ",", "'" ) );
		assertEquals( write( [ [ 1, "", 3 ], [ "", 2, "" ] ] )
		            , read( "1,,3N,2,N", "N", ",", "'" ) );
		assertEquals( write( [ [ 1, "", 3 ], [ "", 2, "" ] ] )
		            , read( "'1',,'3'N,'2',N", "N", ",", "'" ) );
	}

	public function testEofBug() {
		assertAnyException( reader( new StringInput( "" ), "\n", " ", "'" ).readRecord.bind(null) );
	}

	function input( s:String ):StringInput {
		return new StringInput( s );
	}

	function write( x:Array<Array<Dynamic>> ):String {
		// trace( x );
		return x.toString();
	}

	function read( s:String, nl:String, sep:String, qte:String ):String {
		var r = reader( input( s ), nl, sep, qte );
		var y = [];
		try {
			while ( true )
				y.push( r.readRecord() );
		}
		catch ( e:Eof ) { }
		return write( y );
	}

	private function bi( bs:Array<Int> ):BytesInput {
		var bb = new BytesBuffer();
		for ( b in bs )
			bb.addByte( b );
		return new BytesInput( bb.getBytes() );
	}


}

class TestCSVReaderAsciiExt extends TestCSVReader {

	// public function testAsciiExt() {
	// 	assertEquals( write( [ [11,ch(0xED),13], [21,22,23] ] )
	// 		         , read( "11:"+ch(0xED)+":13$21:22:23$", "$", ":", "'" ) );
	// }

}

class TestCSVReaderUtf8 extends TestCSVReader {

	override function reader( i, nl, sep, qte ) {
		return new Reader( i, nl, sep, qte, true );
	}

	public function testUtf8Crit() {
		assertEquals( write( [ ["11':'11",12,"'13ϝΞ13'"], ["'",22,23] ] )
			         , read( "'11'':''11':12:'''13ϝΞ13'''ϝΞ'''':22:23ϝΞ", "ϝΞ", ":", "'" ) );
		assertEquals( write( [ ["11'Ϟ'11",12,"'13$%13'"], ["'",22,23] ] )
			         , read( "'11''Ϟ''11'Ϟ12Ϟ'''13$%13'''$%''''Ϟ22Ϟ23$%", "$%", "Ϟ", "'" ) );
		assertEquals( write( [ ["11ͱ:ͱ11",12,"ͱ13$%13ͱ"], ["ͱ",22,23] ] )
			         , read( "ͱ11ͱͱ:ͱͱ11ͱ:12:ͱͱͱ13$%13ͱͱͱ$%ͱͱͱͱ:22:23$%", "$%", ":", "ͱ" ) );
		assertEquals( write( [ ["11ͱϞͱ11",12,"ͱ13ϝΞ13ͱ"], ["ͱ",22,23] ] )
			         , read( "ͱ11ͱͱϞͱͱ11ͱϞ12Ϟͱͱͱ13ϝΞ13ͱͱͱϝΞͱͱͱͱϞ22Ϟ23ϝΞ", "ϝΞ", "Ϟ", "ͱ" ) );
	}

	public function testUtf8NonCrit() {
		assertEquals( write( [ ["κκ':'κκ","κλ","'κμ<>κμ'"], ["'","λλ","λμ"] ] )
			         , read( "'κκ'':''κκ':κλ:'''κμ<>κμ'''<>'''':λλ:λμ<>", "<>", ":", "'" ) );
	}

	public function test3ByteUtf8() {
		assertEquals( write( [ ["1ઁ1","1ઁ2","1ઁ3" ], ["2ઁ1","2ઁ2","2ઁ3"] ] )
			         , read( "1ઁ1:1ઁ2:1ઁ3<>2ઁ1:2ઁ2:2ઁ3", "<>", ":", "'" ) );
	}

	public function test4ByteUtf8() {
		assertEquals( write( [ ["1𐅄1","1𐅄2","1𐅄3" ], ["2𐅄1","2𐅄2","2𐅄3"] ] )
			         , read( "1𐅄1:1𐅄2:1𐅄3<>2𐅄1:2𐅄2:2𐅄3", "<>", ":", "'" ) );
	}

	public function testReplacement() {
		assertEquals( 0xEFBFBD, Tools.readChar( bi([0xED]), true ) );
	}

}

class MeasureCSVReader extends TestCase {
#if MEASURE_CSV
	function input( utf8 ) {
		var s = new StringBuf();
		for ( x in 0...10000 )
			if ( utf8 )
				s.add( "'11'':''11':12:'''13<>13'''<>'''':22:23<>" );
			else
				"1𐅄1:1𐅄2:1𐅄3<>2𐅄1:2𐅄2:2𐅄3";
		return new StringInput( s.toString() );
	}

	function measure( utf8 ) {
		var r = new Reader( input( utf8 ), "<>", ":", "'", utf8 );
		var t0 = Timer.stamp();
		try {
			while ( true )
				r.readRecord();
		}
		catch ( e:Eof ) { }
		var t1 = Timer.stamp();
		return 5e-5*( t1 - t0 );
	}

	public function testAscii() {
		trace( "\nMeasureCSVReader ASCII: "+measure( false ) );
		assertTrue( true );
	}


	public function testUtf8() {
		trace( "\nMeasureCSVReader UTF-8: "+measure( true ) );
		assertTrue( true );
	}
#end
}

class TestTools extends TestCase {

	public function testGetBufContents() {
		var bb = function ( bs:Array<Int> ) { var bb = new BytesBuffer(); for ( b in bs ) bb.addByte( b ); return bb; };
		#if ( neko || cpp )
		assertEquals( "ed", Bytes.ofString( Tools.getBufContents(bb([0xED]),false) ).toHex() );
		#else
		assertEquals( "c3ad", Bytes.ofString( Tools.getBufContents(bb([0xED]),false) ).toHex() );
		#end
	}

}

class TestEscaperAsciiExt extends TestCase {

	private function escaper( nl, sep, qte ) {
		return new Escaper( false, nl, sep, qte );
	}

	public function testEncodingPreservation() {
		var e = escaper( "\n", ",", "\"" );
		assertEquals( "i", e.escape( "i" ) );
		assertEquals( String.fromCharCode(0xED), e.escape( String.fromCharCode(0xED) ) ); // í in latin-1
	}

}

class TestEscaperUtf8 extends TestEscaperAsciiExt {

	override private function escaper( nl, sep, qte ) {
		return new Escaper( true, nl, sep, qte );
	}

	override public function testEncodingPreservation() {
		var e = escaper( "\n", ",", "\"" );
		assertEquals( "i", e.escape( "i" ) );
		assertEquals( "í", e.escape( "í" ) );
	}

}

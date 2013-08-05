import format.csv.Reader;
import haxe.io.Eof;
import haxe.io.StringInput;

@:access( format.csv.Reader )
class TestCSV extends TestCase {

	public function testConstruction() {
		var i = new StringInput( "test string" );

		// good
		var a = new Reader( i, "N", "S", "Q");
		assertEquals( NL0_noNL1, a.getCharType( "N".charCodeAt( 0 ) ) );
		var b = new Reader( i, "NL", "S", "Q");

		// bad
		assertAnyException( Reader.new.bind( i,    "",  "S",  "Q") );
		assertAnyException( Reader.new.bind( i, "NLX",  "S",  "Q") );
		assertAnyException( Reader.new.bind( i,  "NL",   "",  "Q") );
		assertAnyException( Reader.new.bind( i,  "NL", "SX",  "Q") );
		assertAnyException( Reader.new.bind( i,  "NL",  "S",   "") );
		assertAnyException( Reader.new.bind( i,  "NL",  "S", "QX") );

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

	public function testErrors() {
		// the reader should also be set in some sort of invalid state
		assertTrue( false );
	}

	public function testAsciiExt() {
		// not necessary for now
		assertTrue( true );
	}

	public function testUtf8() {
		// not Utf8 capable/tested yet
		assertTrue( false );
	}

	function input( s:String ):StringInput {
		return new StringInput( s );
	}

	function write( x:Array<Array<Dynamic>> ):String {
		// trace( x );
		return x.toString();
	}

	function read( s:String, nl:String, sep:String, qte:String ):String {
		var r = new Reader( input( s ), nl, sep, qte );
		var y = [];
		try {
			while ( true )
				y.push( r.readRecord() );
		}
		catch ( e:Eof ) {

		}
		return write( y );
	}

}

package ;

import haxe.io.*;
import haxe.Timer;

import format.ett.Data;
import format.ett.Error;
import format.ett.Geometry;
import format.ett.Reader;
import format.ett.Writer;

@:access( format.ett.ETTReader )
class TestETTReader extends TestCase {

	public function testSamples() {
		assertEqualSerialized( getData(1,1), read( getSample(1,1) ) );
		assertEqualSerialized( getData(1,2), read( getSample(1,2) ) );
		assertEqualSerialized( getData(2,1), read( getSample(2,1) ) );
		assertEqualSerialized( getData(2,2), read( getSample(2,2) ) );
	}

	public function testHeaderTypeParsing() {
		var r = std.Type.createEmptyInstance( Reader );
		r.info = new FileInfo( "\n", UTF8, ",", "\"", ""
		, [ new Field( "test", TUnknown("test" ) ) ] );
		r.context = 0;

		assertEqualSerialized( TString, r.parseType( "String" ) );
		assertEqualSerialized( TTrim(TString), r.parseType( "Trim<String>" ) );
		assertEqualSerialized( TNull(TString), r.parseType( "Null<String>" ) );
		assertEqualSerialized( TNull(TTrim(TString)), r.parseType( "Null<Trim<String>>" ) );

		assertEqualSerialized( TString, r.validateType( TString) );
		assertEqualSerialized( TTrim(TString), r.validateType( TTrim(TString) ) );
		assertEqualSerialized( TNull(TString), r.validateType( TNull(TString) ) );
		assertEqualSerialized( TNull(TTrim(TString)), r.validateType( TNull(TTrim(TString)) ) );
	}

	public function testNotNullableValues() {
		var r = std.Type.createEmptyInstance( Reader );
		r.info = new FileInfo( "\n", UTF8, ",", "\"", ""
		, [ new Field( "test", TUnknown("test" ) ) ] );
		r.context = 0;

		// successes
		assertNoException( r.parseData.bind( " ", TString ) );

		// expected failures
		assertAnyException( r.parseData.bind( "", TBool ) );
		assertAnyException( r.parseData.bind( " ", TBool ) );
		assertAnyException( r.parseData.bind( "", TInt ) );
		assertAnyException( r.parseData.bind( " ", TInt ) );
		assertAnyException( r.parseData.bind( "", TFloat ) );
		assertAnyException( r.parseData.bind( " ", TFloat ) );
		assertAnyException( r.parseData.bind( "", TString ) );
		assertAnyException( r.parseData.bind( "", TDate ) );
		assertAnyException( r.parseData.bind( " ", TDate ) );
		assertAnyException( r.parseData.bind( "", TTimestamp ) );
		assertAnyException( r.parseData.bind( " ", TTimestamp ) );
		assertAnyException( r.parseData.bind( "", THaxeSerial ) );
		assertAnyException( r.parseData.bind( " ", THaxeSerial ) );
		assertAnyException( r.parseData.bind( "", TTrim(TString) ) );
		assertAnyException( r.parseData.bind( " ", TTrim(TString) ) );
	}

	public function testNullableValues() {
		var r = std.Type.createEmptyInstance( Reader );
		r.info = new FileInfo( "\n", UTF8, ",", "\"", ""
		, [ new Field( "test", TUnknown("test" ) ) ] );
		r.context = 0;

		assertEquals( null, r.parseData( "", TNull(TBool) ) );
		assertEquals( null, r.parseData( " ", TNull(TBool) ) );
		assertEquals( null, r.parseData( "", TNull(TInt) ) );
		assertEquals( null, r.parseData( " ", TNull(TInt) ) );
		assertEquals( null, r.parseData( "", TNull(TFloat) ) );
		assertEquals( null, r.parseData( " ", TNull(TFloat) ) );
		assertEquals( null, r.parseData( "", TNull(TString) ) );
		assertEquals( " ", r.parseData( " ", TNull(TString) ) );
		assertEquals( null, r.parseData( "", TNull(TDate) ) );
		assertEquals( null, r.parseData( " ", TNull(TDate) ) );
		assertEquals( null, r.parseData( "", TNull(TTimestamp) ) );
		assertEquals( null, r.parseData( " ", TNull(TTimestamp) ) );
		assertEquals( null, r.parseData( "", TNull(THaxeSerial) ) );
		assertEquals( null, r.parseData( " ", TNull(THaxeSerial) ) );
		assertEquals( null, r.parseData( "", TNull(TTrim(TString)) ) );
		assertEquals( null, r.parseData( " ", TNull(TTrim(TString)) ) );
	}

	public function testParseBool() {
		var r = std.Type.createEmptyInstance( Reader );
		r.info = new FileInfo( "\n", UTF8, ",", "\"", ""
		, [ new Field( "test", TUnknown("test" ) ) ] );
		r.context = 0;

		// successes
		assertEquals( true, r.parseData( "true", TBool ) );
		assertEquals( true, r.parseData( " true ", TBool ) );
		assertEquals( false, r.parseData( "false", TBool ) );
		assertEquals( false, r.parseData( " false ", TBool ) );

		// expected failures
		assertAnyException( r.parseData.bind( "a true", TBool ) );
		assertAnyException( r.parseData.bind( "true a", TBool ) );
	}

	public function testParseInt() {
		var r = std.Type.createEmptyInstance( Reader );
		r.info = new FileInfo( "\n", UTF8, ",", "\"", ""
		, [ new Field( "test", TUnknown("test" ) ) ] );
		r.context = 0;

		// successes
		assertEquals( 42, r.parseData( "42", TInt ) );
		assertEquals( 42, r.parseData( "042", TInt ) );
		assertEquals( 42, r.parseData( " 42 ", TInt ) );
		assertEquals( 42, r.parseData( "+42", TInt ) );
		assertEquals( 42, r.parseData( "+042", TInt ) );
		assertEquals( 42, r.parseData( "0x2a", TInt ) );
		assertEquals( 42, r.parseData( "0x2A", TInt ) );
		assertEquals( 42, r.parseData( "0X2A", TInt ) );

		// expected failures
		// this type checking is disabled with ETT_UNSAFE
		assertAnyException( r.parseData.bind( "a", TInt ) );
		assertAnyException( r.parseData.bind( "+", TInt ) );
		assertAnyException( r.parseData.bind( "0x", TInt ) );
		assertAnyException( r.parseData.bind( "a 42", TInt ) );
		assertAnyException( r.parseData.bind( "42 a", TInt ) );
		assertAnyException( r.parseData.bind( "- 42", TInt ) );
		assertAnyException( r.parseData.bind( "-+42", TInt ) );
		assertAnyException( r.parseData.bind( "+0xff", TInt ) );
		assertAnyException( r.parseData.bind( "+xff", TInt ) );
	}

	public function testParseFloat() {
		var r = std.Type.createEmptyInstance( Reader );
		r.info = new FileInfo( "\n", UTF8, ",", "\"", ""
		, [ new Field( "test", TUnknown("test" ) ) ] );
		r.context = 0;

		// successes
		assertEquals( 42, r.parseData( "42", TFloat ) );
		assertEquals( 42.42, r.parseData( "42.42", TFloat ) );
		assertEquals( 42.42, r.parseData( "042.42", TFloat ) );
		assertEquals( 42.42, r.parseData( " 42.42 ", TFloat ) );
		assertEquals( 42.42, r.parseData( "+042.42", TFloat ) );
		assertEquals( 42.42, r.parseData( "4242e-2", TFloat ) );
		assertEquals( 42.42, r.parseData( "4242E-2", TFloat ) );

		// expected failures
		// this type checking is disabled with ETT_UNSAFE
		assertAnyException( r.parseData.bind( "a", TFloat ) );
		assertAnyException( r.parseData.bind( "e10", TFloat ) );
		assertAnyException( r.parseData.bind( "a 42.42", TFloat ) );
		assertAnyException( r.parseData.bind( "42.42 a", TFloat ) );
		assertAnyException( r.parseData.bind( "- 42.42", TFloat ) );
		assertAnyException( r.parseData.bind( "-+42.42", TFloat ) );
		assertAnyException( r.parseData.bind( "4242e+-2", TFloat ) );
	}

	public function testParseString() {
		var r = std.Type.createEmptyInstance( Reader );
		r.info = new FileInfo( "\n", UTF8, ",", "\"", ""
		, [ new Field( "test", TUnknown("test" ) ) ] );
		r.context = 0;

		assertEquals( "42", r.parseData( "42", TString ) );
		assertEquals( "42", r.parseData( "42", TNull(TString) ) );
		assertEquals( " 42 ", r.parseData( " 42 ", TString ) );
		assertEquals( " 42 ", r.parseData( " 42 ", TNull(TString) ) );
		assertEquals( "42", r.parseData( " 42 ", TTrim(TString) ) );
		assertEquals( "42", r.parseData( " 42 ", TNull(TTrim(TString)) ) );
	}

	public function testParseGeometry() {
		var r = std.Type.createEmptyInstance( Reader );
		r.info = new FileInfo( "\n", UTF8, ",", "\"", ""
		, [ new Field( "test", TUnknown("test" ) ) ] );
		r.context = 0;

		// successes
		assertEqualSerialized( new Point(10.,20.), r.parseData( " 10   20  ", TPoint ) );
		assertEqualSerialized( new LineString([new Point(10.,20.),new Point(30.,40.)])
		, r.parseData( " 10   20  , 30  40 ", TLineString ) );
		assertEqualSerialized( new Point(10.,20.), r.parseData( " 10   20  ", TGeometry(TPoint) ) );
		assertEqualSerialized( new LineString([new Point(10.,20.),new Point(30.,40.)])
		, r.parseData( " 10   20  , 30  40 ", TGeometry(TLineString) ) );

		// expected failures
		assertAnyException( r.parseData.bind( "10", TPoint ) );
		assertAnyException( r.parseData.bind( "10 20 30", TPoint ) );
		assertAnyException( r.parseData.bind( "10 z", TPoint ) );
	}

	function getSample( major:Int, minor:Int ):BytesInput {
		// trace( haxe.Resource.listNames() );
		var data = haxe.Resource.getBytes( 'res.ett.sample${major}_${minor}' );
		// trace( data.toString().substr( 0, 40 ) );
		// trace( new BytesInput( data ).readAll().toString() );
		return new BytesInput( data );
	}

	function getData( major:Int, minor:Int ):Array<Dynamic> {
		// trace( haxe.Resource.listNames() );
		var data = haxe.Resource.getString( 'res.ett.data${major}_${minor}' );
		// trace( data.substr( 0, 40 ) );
		// trace( haxe.Unserializer.run( data ) );
		return haxe.Unserializer.run( data );
	}

	function read( input:Input ):Array<Dynamic> {
		var r = new Reader( input );
		var data = [];
		try {
			while ( true )
				data.push( r.readRecord() );
		}
		catch ( e:Eof ) { }
		return data;
	}

}

@:access( format.ett.ETTWriter )
class TestETTWriter extends TestCase {

	public function testWriteData() {
		var w = std.Type.createEmptyInstance( Writer );
		var d = { b:false, i:1, f:1.1, fi:1, s:"s"
		        , d:Date.fromString( "2013-08-15" )
		        , t:Date.fromString( "2013-08-15" ).getTime()
		        , hs:[1,null,0] };
		assertEquals( "false", w.writeData( d, "b", TBool ) );
		assertEquals( "1", w.writeData( d, "i", TInt ) );
		assertEquals( "1.1", w.writeData( d, "f", TFloat ) );
		assertEquals( "1", w.writeData( d, "fi", TFloat ) );
		assertEquals( "s", w.writeData( d, "s", TString ) );
		assertEquals( "2013-08-15 00:00:00", w.writeData( d, "d", TDate ) );
		assertEquals( Std.string( d.t ), w.writeData( d, "t", TTimestamp ) );
		assertEquals( "ai1nzh", w.writeData( d, "hs", THaxeSerial ) );
	}

	// public function testWrite() {
		
	// }

}

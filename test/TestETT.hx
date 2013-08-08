package ;

import haxe.io.*;
import haxe.Timer;

import format.ett.Data;
import format.ett.Error;
import format.ett.Reader;

import Type in TypeTools;

@:access( format.ett.Reader )
class TestETTReader extends TestCase {

	public function testSamples() {
		assertEqualSerialized( getData(1,1), read( getSample(1,1) ) );
		assertEqualSerialized( getData(1,2), read( getSample(1,2) ) );
		assertEqualSerialized( getData(2,1), read( getSample(2,1) ) );
		assertEqualSerialized( getData(2,2), read( getSample(2,2) ) );
	}

	public function testHeaderTypeParsing() {
		var r = TypeTools.createEmptyInstance( Reader );
		r.info = new FileInfo();
		r.info.fields = [ new Field( "test", TUnknown("test" ) ) ];
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
		var r = TypeTools.createEmptyInstance( Reader );
		r.info = new FileInfo();
		r.info.fields = [ new Field( "test", TUnknown("test" ) ) ];
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
		var r = TypeTools.createEmptyInstance( Reader );
		r.info = new FileInfo();
		r.info.fields = [ new Field( "test", TUnknown("test" ) ) ];
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
		var r = TypeTools.createEmptyInstance( Reader );
		r.info = new FileInfo();
		r.info.fields = [ new Field( "test", TUnknown("test" ) ) ];
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
		var r = TypeTools.createEmptyInstance( Reader );
		r.info = new FileInfo();
		r.info.fields = [ new Field( "test", TUnknown("test" ) ) ];
		r.context = 0;

		// successes
		assertEquals( 42, r.parseData( "42", TInt ) );
		assertEquals( 42, r.parseData( "042", TInt ) );
		assertEquals( 42, r.parseData( "+042", TInt ) );
		assertEquals( 42, r.parseData( " 42 ", TInt ) );
		assertEquals( 42, r.parseData( "0x2a", TInt ) );

		// expected failures
		// currently all of these succeed on neko and C++!
		// trace( "Std.parseInt( 'a 42' ):" + Std.parseInt( "a 42" ) );
		// trace( "Std.parseInt( '42 a' ):" + Std.parseInt( "42 a" ) );
		// assertAnyException( r.parseData.bind( "a 42", TInt ) );
		// assertAnyException( r.parseData.bind( "42 a", TInt ) );
	}

	public function testParseFloat() {
		var r = TypeTools.createEmptyInstance( Reader );
		r.info = new FileInfo();
		r.info.fields = [ new Field( "test", TUnknown("test" ) ) ];
		r.context = 0;

		// successes
		assertEquals( 42.42, r.parseData( "42.42", TFloat ) );
		assertEquals( 42.42, r.parseData( "042.42", TFloat ) );
		assertEquals( 42.42, r.parseData( "+042.42", TFloat ) );
		assertEquals( 42.42, r.parseData( " 42.42 ", TFloat ) );

		// expected failures
		// currently all of these succeed on neko and C++!
		// trace( "Std.parseFloat( 'a 42.42' ):" + Std.parseFloat( "a 42.42" ) );
		// trace( "Std.parseFloat( '42.42 a' ):" + Std.parseFloat( "42.42 a" ) );
		// assertAnyException( r.parseData.bind( "a 42.42", TFloat ) );
		// assertAnyException( r.parseData.bind( "42.42 a", TFloat ) );
	}

	public function testParseString() {
		var r = TypeTools.createEmptyInstance( Reader );
		r.info = new FileInfo();
		r.info.fields = [ new Field( "test", TUnknown("test" ) ) ];
		r.context = 0;

		assertEquals( "42", r.parseData( "42", TString ) );
		assertEquals( "42", r.parseData( "42", TNull(TString) ) );
		assertEquals( " 42 ", r.parseData( " 42 ", TString ) );
		assertEquals( " 42 ", r.parseData( " 42 ", TNull(TString) ) );
		assertEquals( "42", r.parseData( " 42 ", TTrim(TString) ) );
		assertEquals( "42", r.parseData( " 42 ", TNull(TTrim(TString)) ) );
	}

	function getSample( major:Int, minor:Int ):BytesInput {
		return new BytesInput( haxe.Resource.getBytes( 'res/ett/sample${major}_${minor}' ) );
	}

	function getData( major:Int, minor:Int ):Array<Dynamic> {
		return haxe.Unserializer.run( haxe.Resource.getString( 'res/ett/data${major}_${minor}' ) );
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

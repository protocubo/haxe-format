package ;

class TestHaxe extends TestCase {
	
	public function testEmptyBytes() {
		// https://github.com/HaxeFoundation/haxe/issues/2076
		var b = haxe.io.Bytes.alloc( 0 );
		assertEquals( "", b.toString() );
		assertEquals( "", b.readString( 0, 0 ) );
		var bb = new haxe.io.BytesBuffer();
		assertEquals( "", bb.getBytes().toString() );
		bb = new haxe.io.BytesBuffer();
		assertEquals( "", bb.getBytes().readString( 0, 0 ) );
	}

	public function testCharSequence() {
		// 0...9
		assertEquals( "1".code, "0".code+1 );
		assertEquals( "2".code, "1".code+1 );
		assertEquals( "3".code, "2".code+1 );
		assertEquals( "4".code, "3".code+1 );
		assertEquals( "5".code, "4".code+1 );
		assertEquals( "6".code, "5".code+1 );
		assertEquals( "7".code, "6".code+1 );
		assertEquals( "8".code, "7".code+1 );
		assertEquals( "9".code, "8".code+1 );
		// a...f
		assertEquals( "b".code, "a".code+1 );
		assertEquals( "c".code, "b".code+1 );
		assertEquals( "d".code, "c".code+1 );
		assertEquals( "e".code, "d".code+1 );
		assertEquals( "f".code, "e".code+1 );
		// A...F
		assertEquals( "B".code, "A".code+1 );
		assertEquals( "C".code, "B".code+1 );
		assertEquals( "D".code, "C".code+1 );
		assertEquals( "E".code, "D".code+1 );
		assertEquals( "F".code, "E".code+1 );
	}

	public function testArrayPushReturn() {
		var x = [];
		for ( i in 0...1000 )
			assertEquals( i+1, x.push( i ) ); // this is NOT the spec
	}

	public function testStringFromCharCode() {
		#if ( neko || cpp )
		assertEquals( "ed", haxe.io.Bytes.ofString( String.fromCharCode( 0xed ) ).toHex() );
		#else
		assertEquals( "c3ad", haxe.io.Bytes.ofString( String.fromCharCode( 0xed ) ).toHex() );
		#end
	}

}

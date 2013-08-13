package ;

class TestHaxe extends TestCase {
	public function testEmptyBytes() {
		var b = haxe.io.Bytes.alloc( 0 );
		assertEquals( "", b.toString() ); // fails for C++
		// https://github.com/HaxeFoundation/haxe/issues/2076
		var bb = new haxe.io.BytesBuffer();
		assertEquals( "", bb.getBytes().toString() );
	}
}

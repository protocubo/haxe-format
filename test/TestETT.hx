package ;

import haxe.io.*;
import haxe.Timer;

import format.ett.Data;
import format.ett.Error;
import format.ett.Reader;

class TestETTReader extends TestCase {

	public function testSamples() {
		assertEqualSerialized( getData(1,1), read( getSample(1,1) ) );
		assertEqualSerialized( getData(1,2), read( getSample(1,2) ) );
		assertEqualSerialized( getData(2,1), read( getSample(2,1) ) );
		assertEqualSerialized( getData(2,2), read( getSample(2,2) ) );
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

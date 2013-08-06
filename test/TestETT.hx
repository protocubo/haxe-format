package ;

import haxe.io.Eof;
import haxe.io.StringInput;
import haxe.io.BytesInput;
import haxe.io.Input;
import haxe.Timer;

import format.ett.Data;
import format.ett.Error;
import format.ett.Reader;

class TestETTReader extends TestCase {

	function getSample( major:Int, minor:Int ):BytesInput {
		return new BytesInput( haxe.Resource.getBytes( 'res/ett/sample${major}_${minor}' ) );
	}

	function getData( major:Int, minor:Int ):Array<Dynamic> {
		// trace( haxe.Unserializer.run( haxe.Resource.getString( 'res/ett/data${major}_${minor}' ) ) );
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

	public function testDumb() {
		trace( "\n"+read( getSample( 1, 1 ) ).join("\n") );
		trace( "\n"+read( getSample( 1, 2 ) ).join("\n") );
		trace( "\n"+read( getSample( 2, 1 ) ).join("\n") );
		trace( "\n"+read( getSample( 2, 2 ) ).join("\n") );

		// getData( 1, 1 );
		// getData( 1, 2 );
	}

}

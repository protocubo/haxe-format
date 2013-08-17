package ;

import TestCSV;
import TestETT;

class Main {

	function new() {
		var runner = new haxe.unit.TestRunner();
		var tests = [
		   new TestHaxe()
		 , new TestCSV.TestCSVReader()
		 , new TestCSV.TestCSVReaderUtf8()
		 , new TestCSV.MeasureCSVReader()
		 , new TestETT.TestETTReader()
		 , new TestETT.TestETTWriter()
		];
		for ( t in tests )
			runner.add( t );
		runner.run();
	}

	static function main() {
		var app = new Main();
	}

}

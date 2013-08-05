class Main {

	function new() {
		var runner = new haxe.unit.TestRunner();
		var tests = [
			new TestCSV.TestCSVReader()
		 , new TestCSV.TestCSVReaderUtf8()
		 , new TestCSV.MeasureCSVReader()
		];
		for ( t in tests )
			runner.add( t );
		runner.run();
	}

	static function main() {
		var app = new Main();
	}

}

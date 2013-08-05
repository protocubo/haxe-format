class Main {

	function new() {
		var runner = new haxe.unit.TestRunner();
		for ( t in [ new TestCSV(), new TestCSV.TestCSVUtf8() ] )
			runner.add( t );
		runner.run();
	}

	static function main() {
		var app = new Main();
	}

}

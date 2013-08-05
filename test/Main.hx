class Main {

	function new() {
		var runner = new haxe.unit.TestRunner();
		runner.add( new TestCSV() );
		runner.run();
	}

	static function main() {
		var app = new Main();
	}

}

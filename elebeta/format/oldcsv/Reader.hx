package elebeta.format.oldcsv;

import haxe.io.Input;
import haxe.io.Eof;

typedef Reader = CSVReader;

class CSVReader {

    var input:Input;
    var reader:format.csv.Reader;

    public function new(input:Input, ?newline="\n", ?separator=",", ?quote="\"", ?utf8=false)
    {
        this.input = input;

        var cons = utf8 ? format.csv.Utf8Reader.new : format.csv.Reader.new;
        reader = cons(separator, quote, [newline]);
        reader.reset(null, input);
    }

    public function close():Void
    {
        if ( input != null ) {
            input.close();
            input = null;
        }
    }

    public function readRecord(?reuse:Array<String>):Array<String>
    {
        if ( input == null )
            throw "No input stream (probably it has already been closed)";

        if (!reader.hasNext())
            throw new Eof();

        return reader.next();
    }

}


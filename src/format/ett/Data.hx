package format.ett;

import haxe.io.Bytes;

class FileInfo {

	public var newline:String; // NEWLINE-<NL>
	public var encoding:Encoding; // CODING-<ENC>
	public var separator:String; // SEPARATOR-<SEP>
	public var escape:String; // ESCAPE-<QTE>
	public var className:String; // CLASS-<NAME>
	public var fields:Array<Field>;

	public function new() {
		newline = "\n";
		encoding = ISO;
		separator = ",";
		escape = "\"";
		className = "";
		fields = [];
	}

	public function toString() {
		return "Newline: 0x"+Bytes.ofString( newline ).toHex()+"\n"
		+ "Encoding: "+encoding+"\n"
		+ "Separator: "+separator+"\n"
		+ "Escape: "+escape+"\n"
		+ "Class name: "+className+"\n"
		+ "Fields:\n\t"+fields.join( "\n\t" )+"\n";
	}

}

class Field {

	public var name:String;
	public var type:Type;

	public function new( _name, _type ) {
		name = _name;
		type = _type;
	}

	public function toString() {
		return "'"+name+"' : "+type;
	}

}

enum Encoding {
	ISO; // ISO
	UTF8; // UTF-8
}

enum Type {
	TNull( of:Type );
	TBool;
	TInt;
	TFloat;
	TString;
	TDate;
	TTimestamp;
	THaxeSerial;
	TTrim( s:Type );
}

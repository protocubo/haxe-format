Elebeta Text Tables (ETT)
================================================================================


1. Introduction
--------------------------------------------------------------------------------

ETT extends Comma-Separated Values (CSV, [RFC 4180](http://tools.ietf.org/html/rfc4180)): data is stored in ~~comma-seperated~~ something-separated values and also follows the same escaping rules from RFC 4180. However, ETT allows for arbitrary newline sequences, separator characters and escaping characters, that are specified in the file itself. Additionally ETT supports schema references and enforces column naming and column typing.


2. Structure
--------------------------------------------------------------------------------

An ETT file has two sections: a header section and a data section, both of them CSV compatible. The first part of the header (where all CSV parsing settings for the rest of the document are defined) is not actually in CSV, but should still be readable by most programs.

##2.1 Header

The header is composed of CSV parsing settings, a schema reference and column definitions (column types and column names).

###2.1.1 CSV parsing settings

All CSV parsing settings follow the format

	<keyword>-<value><newline sequence>

where value is a non-quoted (or escaped) string.

####2.1.1.1 Newline configuration (LF, CR+LF or other)

The newline sequence used throughout the file will appear after the NEWLINE- keyword; it can be any 1 or 2 length sequence of Unicode characters, however common LF or CR+LF sequence are recommended on most cases.

	NEWLINE-<newline sequence>

_From now on, the selected newline sequence will be referred to as {nl}._

####2.1.1.2 Encoding

The encoding used on the file: either UTF-8 or ISO (local code page).

	CODING-UTF-8{nl}
	CODING-ISO{nl}

####2.1.1.3 Separator configuration

The value separator used in the document; it can be any Unicode character.

	SEPARATOR-<separator>{nl}

_From now on, the selected separator will be referred to as {sp}._

####2.1.1.4 Escape configuration

The character used to escape itself, separators and newline sequences in values; it can be any Unicode character.

	ESCAPE-<escape character>{nl}

_From now on, the selected escape character will be referred to as {esc}._

###2.1.2 Optionally blank schema name

ETT supports embedding a reference to a schema, so that applications can more easily identify, validate and process these files automatically. A common usage for this it to have it set as the fully qualified Haxe class name used for the records.

	CLASS-<optionally blank schema name>{nl}

###2.1.2 Column types

	<1st column type>{sp}<2nd column>{sp}>...<nth column>{nl}

Type definitions are always trimmed for whitespace.

The types are:

####2.1.3.1 Basic types:

	Bool           a true or false enumeration
	Int            a 32-bit integer
	Float          a 64-bit floating point number
	String         locally encoded text
	Date           local date
	Timestamp      milliseconds from Unix epoch in milliseconds
	HaxeSerial     Haxe serialized data

None of these are, by themselves, nullable.

####2.1.3.2 Nullables:

Any type may be wrapped by Null<> for it to be interpreted as nullable.

	Null<Bool>
	Null<Int>
	...
	Null<HaxeSerial>

####2.1.3.3 Geometry:

	Geometry<Point>        a point (an object with x,y coordinates)
	Geometry<LineString>   a sequence of points

####2.1.3.4 Other types that may be added in the future:

	Base16
	Base64
	SI<[meters],[kilograms],[seconds]>


###2.1.3 Column names

	<1st column name>{sp}<2nd column>{sp}>...<nth column>{nl}

Column names are always trimmed for whitespace.

**ATTENTION**: column names must be unique.


##2.2 Data

Table records in CSV format


3 Data encoding and other format considerations
--------------------------------------------------------------------------------

##3.1 Escaping

Default RFC 4180 escaping rules apply.

##3.2 Null encoding

A blank field (empty string) is always interpreted as a null. On trimmed fields, a resulting empty string will also be treated as a null.

##3.3 Boolean encoding

	true
	false

Always trimmed for whitespace.

##3.4 Integer encoding

For now, any Haxe supported integer text encoding:

	128
	0x80

Always trimmed for whitespace.

**ATTENTION**: all integer should fit in the standard Haxe 32-bit integer.

##3.5 Floating point number encoding

For now, any Haxe supported integer text encoding:

	1.1
	1.
	.1
	11e-1

Always trimmed for whitespace.

##3.6 String encoding

...

May be wrapped by Trim<> for whitespace trimming.

##3.7 Date and timestamp encoding

For date encoding, follow the standard Date.hx rules.

For timestamp encoding, this should be any floating point UTC timestamp, with **milliseconds** since Unix epoch.

Always trimmed for whitespace.

##3.8 Haxe serialization format

Follows the [Haxe Serialization Format](http://haxe.org/manual/serialization/format).

Always trimmed for whitespace.

##3.9 Geometry

Both Point and LineString consist on the internal representation of the WKT (well known text) for these types of geospacial objects. Coordinates are assumed to be in the WGS 84 reference coordinate system and in decimal degrees.

###3.9.1 Point

	<x coordinate> <y coordinate>

###3.9.2 LineString

	<point 0>, <point 1>, ..., <point n>

##3.10 End of file

Properly formated files should end with a newline. However, readers should be able to parse files without the ending newline.


4 Examples
--------------------------------------------------------------------------------

RodoTollSim Node File (schema Elebeta:RodoTollSim:Node), making heavy use of the auto trimming of non String fields:

	NEWLINE-
	CODING-ISO
	SEPARATOR-|
	ESCAPE-"
	CLASS-example.Node
	Int|      Geometry<Point>
	 id|          coordinates
	  1|-40.298736 -20.310141
	  2|-40.291990 -20.302984
	  3|-40.311600 -20.310500

Alternative (bare bones) RodoTollSim Node File (schema Elebeta:RodoTollSim:Node):

	NEWLINE-
	CODING-ISO
	SEPARATOR-|
	ESCAPE-"
	CLASS-example.Node
	Int|Geometry<Point>
	id|coordinates
	1|-40.298736 -20.310141
	2|-40.291990 -20.302984
	3|-40.311600 -20.310500

RodoTollSim Link File (schema Elebeta:RodoTollSim:Link) making heavy use of the auto trimming of non String fields:

	NEWLINE-
	CODING-ISO
	SEPARATOR-|
	ESCAPE-"
	CLASS-example.Link
	Int|        Int|         Int|   Float|   Int|Float
	 id|startNodeId|finishNodeId|distance|typeId| toll
	  1|          1|           2|      69|    50|    0
	  2|          2|           1|      81|    30|  3.0
	  3|          2|           3|     159|    70|    0
	  4|          3|           2|     158|    80|    0

Alternative (bare bones) RodoTollSim Link File (schema Elebeta:RodoTollSim:Link):

	NEWLINE-
	CODING-ISO
	SEPARATOR-|
	ESCAPE-"
	CLASS-example.Link
	Int|Int|Int|Float|Int|Float
	id|startNodeId|finishNodeId|distance|typeId|toll
	1|1|2|69|50|0
	2|2|1|81|30|3.0
	3|2|3|159|70|0
	4|3|2|158|80|0

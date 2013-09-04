Elebeta Text Tables (ETT)
================================================================================

1. Introduction
--------------------------------------------------------------------------------

This format is based of CSV (Comma-Separated Values), in its purest form:
it stores data in a SOMETHING-Separated Values format.

For more information on CSV, check [RFC 4180](http://tools.ietf.org/html/rfc4180):
Common Format and MIME Type for Comma-Separated Values (CSV) Files.

2. Structure
--------------------------------------------------------------------------------

The format has essencially two sections: a header section and a data section.
While the data section is totally in CSV format, the first part of the header
is not (although it is still CSV readable), and that is where all CSV settings
are defined.

##2.1 Header

###2.1.1 CSV metadata

####2.1.1.1 Newline configuration (LF, CR+LF or other)

The newline sequence used throughout the file will appear
after the NEWLINE keyword.

```
NEWLINE-<newline sequence>
```

On the rest of this document the selected newline sequence
will be called by {nl}.

####2.1.1.2 Encoding

The encoding used on the file: either UTF-8 or ISO (with
local code page).

```
CODING-<UTF-8 or ISO>{nl}
```

####2.1.1.3 Separator configuration

```
SEPARATOR-<separator character>{nl}
```

####2.1.1.4 Escape configuration

```
ESCAPE-<escape character>{nl}
```

###2.1.2 Optionally blank schema name

```
CLASS-<optionally blank schema name>{nl}
```

###2.1.2 Column types

```
<1st column type>{sp}<2nd column>{sp}>...<nth column>{nl}
```

Type definitions are always trimmed for whitespace.

The types are:

####2.1.3.1 Basic types (CANNOT BE NULL):

```
Bool           a true or false enumeration
Int            a 32-bit integer
Float          a 64-bit floating point number
String         locally enconded text
Date           local date
Timestamp      utc timestamp from unix epoch in miliseconds
HaxeSerial     haxe serialized data
```

####2.1.3.2 Nullables:

Any type may be wrapped by Null<> and interpreted as
nullable.

```
Null<Bool>
Null<Int>
...
Null<HaxeSerial>
```

####2.1.3.3 Geometry:

Two Geometry types have been implemented: Point and LineString.

####2.1.3.4 In the not so near future, there may be some advanced unit
support.

```
SI<[meters],[kilograms],[seconds]>
```

####2.1.3.4 Other types that may be added soon:

```
Base16
Base64
```

###2.1.3 Column names

```
<1st column name>{sp}<2nd column>{sp}>...<nth column>{nl}
```

Column names are always trimmed for whitespace.

**ATTENTION**: column names must be unique.

##2.2 Data

Table records in CSV format

3 Data encoding and other format considerations
--------------------------------------------------------------------------------

##3.1 Escaping

Default RFC 4180 escaping rules.

##3.2 Null encoding

Blank field (empty string) is always null.

For trimmed fields, an empty trimmed string will also result in null.

##3.3 Boolean encoding

```
true
false
```

Always trimmed for whitespace.

##3.4 Integer encoding

For now, any Haxe supported integer text encoding:

```
128
0x80
```

Always trimmed for whitespace.

**ATTENTION**: all integer should fit in the standard Haxe 32-bit integer.

##3.5 Floating point number encoding

For now, any Haxe supported integer text encoding:

```
1.1
1.
.1
11e-1
```

Always trimmed for whitespace.

##3.6 String encoding

...

May be wrapped by Trim<> for whitespace trimming.

##3.7 Date and timestamp encoding

For date encoding, follow the standard Date.hx rules.

For timestamp encoding, this should be any floating point UTC timestamp,
with **miliseconds** since Unix epoch.

Always trimmed for whitespace.

##3.8 Haxe serialization format

Follow the Haxe Serialization Format docs. Object and string caches are not
well specified there, so one should make sure that everything is readable
and writtable by the standard Haxe classes/tools.

Always trimmed for whitespace.

##3.9 End of file

Properlly formated files should end with a newline. However, readers should
be able to parse files without the ending newline.



4 Examples
--------------------------------------------------------------------------------

RodoTollSim Node File (schema Elebeta:RodoTollSim:Node), making heavy use
 of the auto trimming of non String fields.

```
NEWLINE-
CODING-ISO
SEPARATOR-|
ESCAPE-"
CLASS-elebeta.ett.rodoTollSim.Node
Int|     Float|     Float
 id|         x|         y
  1|-40.298736|-20.310141
  2|-40.291990|-20.302984
  3|-40.311600|-20.310500
```

Alternative (bare bones) RodoTollSim Node File (schema Elebeta:RodoTollSim:Node)

```
NEWLINE-
CODING-ISO
SEPARATOR-|
ESCAPE-"
CLASS-elebeta.ett.rodoTollSim.Node
Int|Float|Float
id |x|y
1|-40.298736|-20.310141
2|-40.291990|-20.302984
3|-40.311600|-20.310500
```

RodoTollSim Link File (schema Elebeta:RodoTollSim:Link) making heavy use of
 the auto trimming of non String fields.

```
NEWLINE-
CODING-ISO
SEPARATOR-|
ESCAPE-"
CLASS-elebeta.ett.rodoTollSim.Link
Int|        Int|         Int|   Float|   Int|Float
 id|startNodeId|finishNodeId|distance|typeId| toll
  1|          1|           2|      69|    50|    0
  2|          2|           1|      81|    30|  3.0
  3|          2|           3|     159|    70|    0
  4|          3|           2|     158|    80|    0
```

Alternative (bare bones) RodoTollSim Link File (schema Elebeta:RodoTollSim:Link)

```
NEWLINE-
CODING-ISO
SEPARATOR-|
ESCAPE-"
CLASS-elebeta.ett.rodoTollSim.Link
Int|Int|Int|Float|Int|Float
id|startNodeId|finishNodeId|distance|typeId|toll
1|1|2|69|50|0
2|2|1|81|30|3.0
3|2|3|159|70|0
4|3|2|158|80|0
```

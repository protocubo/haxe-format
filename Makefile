all: neko cpp cpp64

neko:
	################################################################################
	###   UNIT TESTS - Neko (local)                                              ###
	################################################################################
	haxe ${HXFLAGS} unit_tests.neko.hxml
	neko exp/unit_tests/neko/unit_tests.n
.PHONY: neko

cpp:
	################################################################################
	###   UNIT TESTS - C++ (32 bits)                                             ###
	################################################################################
	haxe ${HXFLAGS} unit_tests.cpp.hxml
	exp/unit_tests/cpp/local/Main
.PHONY: cpp

cpp64:
	################################################################################
	###   UNIT TESTS - C++ (64 bits)                                             ###
	################################################################################
	haxe ${HXFLAGS} unit_tests.cpp64.hxml
	exp/unit_tests/cpp/local64/Main
.PHONY: cpp64

java:
	################################################################################
	###   UNIT TESTS - Java (local)                                              ###
	################################################################################
	haxe ${HXFLAGS} unit_tests.java.hxml
	java -jar exp/unit_tests/java/java.jar
.PHONY: java

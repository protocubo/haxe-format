HAXECMD = haxe

all: neko-dce java-dce cpp cpp64 swf

neko-dce:
	################################################################################
	###   UNIT TESTS - Neko (local, dce=full)                                    ###
	################################################################################
	mkdir -p exp/unit_tests/neko
	${HAXECMD} ${HXFLAGS} -dce full unit_tests.neko.hxml
	neko exp/unit_tests/neko/unit_tests.n
neko:
	################################################################################
	###   UNIT TESTS - Neko (local)                                              ###
	################################################################################
	mkdir -p exp/unit_tests/neko
	${HAXECMD} ${HXFLAGS} unit_tests.neko.hxml
	neko exp/unit_tests/neko/unit_tests.n
.PHONY: neko-dce neko

cpp:
	################################################################################
	###   UNIT TESTS - C++ (32 bits)                                             ###
	################################################################################
	mkdir -p exp/unit_tests
	${HAXECMD} ${HXFLAGS} unit_tests.cpp.hxml
	exp/unit_tests/cpp/local/Main
.PHONY: cpp

cpp64:
	################################################################################
	###   UNIT TESTS - C++ (64 bits)                                             ###
	################################################################################
	mkdir -p exp/unit_tests
	${HAXECMD} ${HXFLAGS} unit_tests.cpp64.hxml
	exp/unit_tests/cpp/local64/Main
.PHONY: cpp64

java-dce:
	################################################################################
	###   UNIT TESTS - Java (local, dce=full)                                    ###
	################################################################################
	${HAXECMD} ${HXFLAGS} -dce full unit_tests.java.hxml
	java -jar exp/unit_tests/java/Main.jar
java:
	################################################################################
	###   UNIT TESTS - Java (local)                                              ###
	################################################################################
	${HAXECMD} ${HXFLAGS} unit_tests.java.hxml
	java -jar exp/unit_tests/java/Main.jar
.PHONY: java-dce java

swf:
	################################################################################
	###   UNIT TESTS - Flash (swf)                                               ###
	################################################################################
	mkdir -p exp/unit_tests
	${HAXECMD} ${HXFLAGS} unit_tests.swf.hxml
flash: swf
.PHONY: swf flash

package:
	rm -f elebeta-format.zip
	zip -r elebeta-format.zip . -x exp/\* .git/\* .hxsublime_tmp/\* gitstats/\* \
	\*.gitignore
.PHONY: package

install: package
	haxelib local elebeta-format.zip
.PHONY: install

clean:
	rm -f elebeta-format.zip
	rm -Rf exp/unit_tests
.PHONY: clean

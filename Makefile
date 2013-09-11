all: neko java cpp cpp64 swf

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

swf:
	################################################################################
	###   UNIT TESTS - Flash (swf)                                               ###
	################################################################################
	haxe ${HXFLAGS} unit_tests.swf.hxml
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
	rm -Rf exp/unit_tests/neko/*.n
	rm -Rf exp/unit_tests/java/obj exp/unit_tests/java/src exp/unit_tests/java/cmd exp/unit_tests/java/*.txt exp/unit_tests/java/*.jar exp/unit_tests/java/manifest
	rm -Rf exp/unit_tests/cpp/local/include exp/unit_tests/cpp/local/obj exp/unit_tests/cpp/local/src exp/unit_tests/cpp/local/*.xml exp/unit_tests/cpp/local/Main exp/unit_tests/cpp/local/*.txt exp/unit_tests/cpp/local/all_objs
	rm -Rf exp/unit_tests/cpp/local64/include exp/unit_tests/cpp/local64/obj exp/unit_tests/cpp/local64/src exp/unit_tests/cpp/local64/*.xml exp/unit_tests/cpp/local64/Main exp/unit_tests/cpp/local64/*.txt exp/unit_tests/cpp/local64/all_objs
	rm -Rf exp/unit_tests/swf/*.swf
.PHONY: clean

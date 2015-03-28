HAXECMD = haxe

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

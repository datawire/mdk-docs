.PHONY: setup all clean-dist clean-venv maindocs mainsetup apidocs

SHELL=/bin/bash

all: clean-dist maindocs apidocs

maindocs:
	mkdir dist
	mkdir dist/latest
	# Static files
	cp -r src/* dist
	cp src/.??* dist
	# Main prose documentation:
	source venv/bin/activate && cd main && make spelling && make html
	mv main/build/html dist/latest/main

mainsetup: venv requirements.txt
	venv/bin/pip install -U -r requirements.txt

setup: mainsetup
	npm install documentation
	curl -L "https://raw.githubusercontent.com/datawire/quark/develop/install.sh" | bash -s

venv:
	virtualenv venv
	mkdir node_modules

apidocs: setup
	~/.quark/bin/quark compile "https://raw.githubusercontent.com/datawire/mdk/develop/quark/mdk-2.0.q"  # not on master yet
	javadoc -sourcepath $$(echo output/java/*/src/main/java | sed "s/ /:/g") -subpackages mdk -d dist/latest/java
	source venv/bin/activate && ~/.quark/bin/quark install --python "https://raw.githubusercontent.com/datawire/mdk/develop/quark/mdk-2.0.q"
	source venv/bin/activate && sphinx-build output/py/mdk-2.0/docs dist/latest/python
	./node_modules/documentation/bin/documentation.js build --shallow --format html --output dist/latest/javascript output/js/mdk-2.0/mdk
	rdoc --output dist/latest/ruby output/rb/mdk-2.0/lib/mdk.rb
	rm -rf output

clean-dist:
	rm -rf dist

clean-venv:
	rm -rf venv node_modules

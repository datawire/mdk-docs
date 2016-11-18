.PHONY: setup all clean-dist clean-venv maindocs mainsetup apidocs apisetup

SHELL=/bin/bash

# Build all docs
all: clean-dist maindocs apidocs

# Do full setup
setup: mainsetup apisetup


### Implementation:

mdk:
	git clone https://github.com/datawire/mdk.git

venv:
	virtualenv venv
	mkdir node_modules

mainsetup: venv requirements.txt
	venv/bin/pip install -U -r requirements.txt

apisetup:
	npm install documentation@4.0.0-beta10
	curl -L "https://raw.githubusercontent.com/datawire/quark/develop/install.sh" | bash -s -- ${QUARKINSTALLARGS} ${QUARKBRANCH}

dist/latest:
	mkdir -p dist/latest

maindocs: dist/latest mainsetup
	# Static files
	cp -r src/* dist
	cp src/.??* dist
	# Main prose documentation:
	source venv/bin/activate && cd main && make spelling && make html
	rm -rf dist/latest/main
	mv main/build/html dist/latest/main

apidocs: mdk
        # Switch to latest tag, presumably latest release:
	cd mdk && git pull && git checkout $$(git describe --abbrev=0 --tags)
	quark compile mdk/quark/mdk-2.0.q
	# Use a better Sphinx index page that only includes MDK package API docs:
	cp -f docs-source-files/index.rst output/py/mdk-2.0/docs
	javadoc -sourcepath $$(echo output/java/*/src/main/java | sed "s/ /:/g") -subpackages mdk -d dist/latest/java
	source venv/bin/activate && quark install --python mdk/quark/mdk-2.0.q
	source venv/bin/activate && sphinx-build output/py/mdk-2.0/docs dist/latest/python
	./node_modules/documentation/bin/documentation.js build --shallow --format html --output dist/latest/javascript output/js/mdk-2.0/mdk
	rdoc --output dist/latest/ruby output/rb/mdk-2.0/lib/mdk.rb
	rm -rf output

clean-dist:
	rm -rf dist

clean-venv:
	rm -rf venv node_modules

.PHONY: rebuild-zip
rebuild-zip:
	rm examples/java-local/*.zip
	cd examples/java-local ; zip -r java-mdk-client.zip java-mdk-client
	cd examples/java-local ; zip -r java-mdk-server.zip java-mdk-server

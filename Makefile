.PHONY: setup all clean-dist clean-venv maindocs mainsetup apidocs apisetup

SHELL=/bin/bash

# Build all docs
all: clean-dist maindocs apidocs

# Do full setup
setup: mainsetup apisetup


### Implementation:

venv:
	virtualenv venv
	mkdir node_modules

mainsetup: venv requirements.txt
	venv/bin/pip install -U -r requirements.txt

apisetup:
	#npm install documentation
	curl -L "https://raw.githubusercontent.com/datawire/quark/develop/install.sh" | bash -s -- ${QUARKINSTALLARGS} ${QUARKBRANCH}

maindocs:
	mkdir dist
	mkdir dist/latest
	# Static files
	cp -r src/* dist
	cp src/.??* dist
	# Main prose documentation:
	source venv/bin/activate && cd main && make spelling && make html
	mv main/build/html dist/latest/main

apidocs:
	quark compile "https://raw.githubusercontent.com/datawire/mdk/develop/quark/mdk-2.0.q"  # not on master yet
	javadoc -sourcepath $$(echo output/java/*/src/main/java | sed "s/ /:/g") -subpackages mdk -d dist/latest/java
	#source venv/bin/activate && quark install --python "https://raw.githubusercontent.com/datawire/mdk/develop/quark/mdk-2.0.q"
	source venv/bin/activate && sphinx-build output/py/mdk-2.0/docs dist/latest/python
	#./node_modules/documentation/bin/documentation.js build --shallow --format html --output dist/latest/javascript output/js/mdk-2.0/mdk
	rdoc --output dist/latest/ruby output/rb/mdk-2.0/lib/mdk.rb
	rm -rf output

clean-dist:
	rm -rf dist

clean-venv:
	rm -rf venv node_modules

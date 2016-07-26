# Documentation for the Microservices Development Kit (MDK)

If you want to read the generated documentation, visit:

https://datawire.github.io/mdk-docs/latest/main/

## Contributing to the documentation

Currently public source version of docs is on `master`, with resulting artifacts in `gh-pages`.

Staging branch is `develop`.

* Main documentation goes in `main/`.
* API docs for each programming language are in `api/python/`, `api/ruby/`, etc.

## Development

To setup the toolchain, run:

    make setup

You can then build the docs by running:

    make all

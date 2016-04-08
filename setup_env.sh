
#!/bin/bash

if [[ "$(uname)" == "Darwin" ]]; then
	brew update
	brew install zeromq --with-libsodium --HEAD
else
	sudo apt-get update
	sudo apt-get install libzmq3-dev
fi
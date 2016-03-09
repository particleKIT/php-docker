# makefile for testing stuff
#
# its optimized for use in a NFS
# environment that uses root_squash
#

NAME=local/apache
DIR=php-docker

.PHONY: all build build-nocache run 

all: build

build:
	cp -Rf $(PWD) /tmp/ &&\
	   	sudo chown -R root:root /tmp/$(DIR) &&\
	   	sudo docker build -t $(NAME) -f /tmp/$(DIR)/Dockerfile /tmp/$(DIR) &&\
		sudo rm -rf /tmp/$(DIR)

run:
	sudo docker run --name=test -ti --rm $(NAME) bash

clean:
	sudo rm -rf sudo rm -rf /tmp/$(DIR) && sudo docker rm -f test

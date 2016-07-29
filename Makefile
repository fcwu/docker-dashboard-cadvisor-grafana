.PHONY: all

all:
	cp -av prometheus docker-compose.yml config.monitoring qpkg/shared/
	docker run -it --rm -v ${PWD}:/src dorowu/qdk2 bash -c "cd /src/qpkg/ && fakeroot /usr/share/qdk2/QDK/bin/qbuild --build-dir build"

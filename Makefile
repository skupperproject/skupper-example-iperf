SIMPLE_IPERF_IMAGE := quay.io/skupper/simple-iperf
DOCKER := docker

docker-build: 
	${DOCKER} build -t ${SIMPLE_IPERF_IMAGE} .

docker-push:
	${DOCKER} push ${SIMPLE_IPERF_IMAGE}
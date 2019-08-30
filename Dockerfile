FROM fedora:30

RUN \
  dnf clean all && \
  dnf install iperf3 -y

USER 1001

#ENTRYPOINT ["/usr/bin/iperf3", "-s"]
EXPOSE 5001

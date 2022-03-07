FROM fedora:35

RUN \
  dnf clean all && \
  dnf install iperf3 -y

USER 1001

#ENTRYPOINT ["/usr/bin/iperf3", "-s"]
EXPOSE 5001

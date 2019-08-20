FROM fedora:30

RUN \
  dnf clean all && \
  dnf install iperf -y

USER 1001

#ENTRYPOINT ["/usr/bin/iperf", "-s"]
EXPOSE 5001

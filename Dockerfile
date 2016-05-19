FROM golang:1.6

ENV TINI_VERSION v0.9.0

# Add Tini
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini

# Run tini
ENTRYPOINT ["/tini", "--"]

# Add cfssl
RUN go get -u github.com/cloudflare/cfssl/cmd/cfssl && \
    go get -u github.com/cloudflare/cfssl/cmd/...

# CFSSL volume
VOLUME /etc/cfssl

# CFSSL service port
EXPOSE 8888

# Run intermediate CA
ADD files/ /root
ADD run.sh /
CMD ["/run.sh"]

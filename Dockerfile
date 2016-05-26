FROM golang:1.6

ENV TINI_VERSION v0.9.0

# Add Tini
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini

# Run tini
ENTRYPOINT ["/tini", "--"]

# Add cfssl
RUN go get -u github.com/cloudflare/cfssl/cmd/cfssl && \
    go get -u github.com/cloudflare/cfssl/cmd/...   && \
    go get bitbucket.org/liamstask/goose/cmd/goose

# Create cfssl user and template database
RUN groupadd -g 1000 cfssl && \
    useradd  -m -d /home/cfssl -s /bin/bash -g 1000 -u 1000 cfssl && \
    cd /home/cfssl && goose -path \
        $GOPATH/src/github.com/cloudflare/cfssl/certdb/sqlite -env production up && \
    mv certstore_production.db certs.db

# CFSSL volume
ENV CA_PATH /etc/cfssl
VOLUME /etc/cfssl

# CFSSL service port
EXPOSE 8888

# Run intermediate CA
ADD files/ /home/cfssl
ADD bin/   /usr/local/bin
ADD run.sh /

USER cfssl
CMD ["/run.sh"]

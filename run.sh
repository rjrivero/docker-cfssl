#!/bin/sh

# Copy default config, if missing
if [ ! -f /etc/cfssl/config-ca.json ]; then
    cp /root/ca-config.json /etc/cfssl/ca-config.json
fi

# Create self-signed CA cert, if there is not any other
if [ ! -f /etc/cfssl/ca.pem ]; then
    if [ ! -f /etc/cfssl/ca-csr.json ]; then
        cp /root/ca-csr.json /etc/cfssl/ca-csr.json
    fi
    cd /etc/cfssl && cfssl gencert -initca ca-csr.json | cfssljson -bare ca -
fi

# Create db_config file, if it does not exist
if [ ! -f /etc/cfssl/db-config.json ]; then
    cp /root/db-config.json /etc/cfssl/db-config.json
fi

# Run service
exec cfssl serve \
    -config /etc/cfssl/ca-config.json \
    -db-config /etc/cfssl/db-config.json \
    -ca /etc/cfssl/ca.pem \
    -ca-key /etc/cfssl/ca-key.pem

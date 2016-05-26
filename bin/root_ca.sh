#!/bin/sh

cd "${CA_PATH}" || exit 1

# Check if the certificate already exists
if [ -f ca.pem ]; then
    echo "Certificate ${CA_PATH}/ca.pem already exists"
    echo "--"
    echo "If you want to overwrite it, then remove it first."
    exit 2
fi

# If not ca-config.json file, add it
if [ ! -f ca-config.json ]; then
    cp "${HOME}/ca-config-root.json" ca-config.json
fi

# If not ca-csr.json file, add it
if [ ! -f ca-csr.json ]; then
    cp "${HOME}/ca-csr-root.json" ca-csr.json
fi

# Create self-signed certificate
if [ -f ca-key.pem ]; then
    echo "** USING EXISTING PRIVATE KEY ${CA_PATH}/ca-key.pem **"
    cfssl gencert -initca -ca-key ca-key.pem ca-csr.json | cfssljson -bare ca
else
    echo "** CREATIG NEW ROOT CA KEY **"
    cfssl gencert -initca ca-csr.json | cfssljson -bare ca
fi

# Fix file permissions
chmod 0400 ca-key.pem
chmod 0444 ca.pem

echo "Self-signed certificate at ${CA_PATH}/ca.pem"

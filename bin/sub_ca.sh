#!/bin/sh

cd "${CA_PATH}" || exit 1

# Check if the certificate already exists
if [ -f ca.pem ]; then
    echo "Certificate ${CA_PATH}/ca.pem already exists"
    echo "--"
    echo "If you want to overwrite it, then remove it first."
    exit 2
fi

# We need the root CA's hostname to sign the cert
if [ -z "$1" ]; then
    echo "Missing root CA host name"
    echo "----------"
    echo "You must provide the root CA's hostname or IP address"
    exit 3
fi

# Create ca-csr.pem
if [ ! -f ca-csr.json ]; then
    cp "${HOME}/ca-csr.json" ca-csr.json
fi

# If given a subordinate name, update ca-csr.json
if [ -z "$2" ]; then
    echo "Missing subordinate CA CN"
    echo "----------"
    echo "You have not provided a CN in the command line."
    echo "The CN found in ${CA_PATH}/ca-csr.json will be used."
else
    SUB_NAME=`echo $2 | sed -e 's/[\/&]/\\&/g'`
    sed -i "s/\"CN\":.*/\·CN\":${SUB_NAME}/" ca-csr.json
fi

# Get root CA certificate
mkdir -p "${CA_PATH}/root-bundle"
curl -d '{"label": "default"}' ${1}/api/v1/cfssl/info  | \
    ca_cert.py "${CA_PATH}/root-bundle/ca-root.pem"

if [ !-f root-bundle/ca-root.pem ]; then
    echo "Unable to retrieve root CA certificate"
    echo "----------"
    echo "Could not get root CA cert from $1"
    exit 3
fi

# Bundle the ca cert
rm -f root-bundle.crt
mkbundle -f root-bundle.crt root-bundle
mkbundle -f sub-bundle.crt  ca.pem
# cfssl requires these files to be writeable
chmod 0644  root-bundle.crt sub-bundle.crt

# Create the certificate and sign it with the remote CA
cfssl gencert -remote "$1" -profile subordinate ca-csr.json \
    | cfssljson -bare ca

# Fix permissions
chmod 0400 ca-key.pem
chmod 0444 ca.pem

echo "Certificate generated at ${CA_PATH}/ca.pem"

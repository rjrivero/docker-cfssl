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

# Create the certificate and sign it with the remote CA
cfssl gencert -remote "$1" -profile subordinate ca-csr.json \
    | cfssljson -bare ca

# Get root CA certificate
mkdir -p "${CA_PATH}/root_bundle"
curl -d '{"label": "default"}' ${1}/api/v1/cfssl/info  | \
    ca_cert.py "${CA_PATH}/root_bundle/ca-root.pem"

if [ ! -f root_bundle/ca-root.pem ]; then
    echo "Unable to retrieve root CA certificate"
    echo "----------"
    echo "Could not get root CA cert from $1"
    exit 3
fi

# Bundle the root ca cert
rm -f root_bundle.crt
mkbundle -f root_bundle.crt root_bundle

# Bundle the sub ca cert
mkdir -p "${CA_PATH}/sub_bundle"
cp "${CA_PATH}/root_bundle/ca-root.pem" "${CA_PATH}/sub_bundle/"
cp "${CA_PATH}/ca.pem" "${CA_PATH}/sub_bundle/"
mkbundle -f sub_bundle.crt sub_bundle

# Build the root CA chain
cat ca.pem root_bundle/ca-root.pem > ca-chain.pem

# Fix permissions
chmod 0400 ca-key.pem
chmod 0444 ca.pem
# cfssl requires these files to be writeable
chmod 0644 root_bundle.crt sub_bundle.crt

echo "Certificate generated at ${CA_PATH}/ca.pem"

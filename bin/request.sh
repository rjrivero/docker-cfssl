#!/usr/bin/env bash

export IFS='
'

export CSR="${1}"
export PROFILE="${2}"

if [ -z "${1}" ]; then
    echo "Usage: ${0} <csr path> <cert. profile>"
    echo "  Cert-profile can be: client, server, both"
    echo "The csr file name must end with '-csr.json'"
    exit -1
fi

if [ -z "$2" ]; then
    echo "Error: Must specify 'client', 'server' or 'both' profile"
    exit -2
fi

cd "/etc/cfssl"
if ! [ -f "${CSR}" ]; then
    echo "Error: could not find ${CSR} relative to `pwd`"
    exit -3
fi

if ! [ "${CSR: -9}" == "-csr.json" ]; then
    echo "Error: CSR filename must end with '-csr.json'"
    exit -4
fi

export BASE=`basename "${CSR}" -csr.json`
export DIRN=`dirname "${CSR}"`

# Generate the certificate
cd "${DIRN}"
cfssl gencert -remote=localhost -profile="${PROFILE}" "${BASE}-csr.json" \
    | cfssljson -bare "${BASE}"
# Build the complete chain
cat "${BASE}.pem" "/etc/cfssl/ca.pem" \
    "/etc/cfssl/root_bundle/ca-root.pem" > "${BASE}-chain.pem"

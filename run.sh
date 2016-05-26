#!/bin/sh

# Create self-signed Root CA cert, if there is not any other
if [ ! -f "${CA_PATH}/ca.pem" ]; then
    /usr/local/bin/root_ca.sh || exit 1
fi

# Prepare config files
/usr/local/bin/common.sh

# Initialize database
if [ ! -f "${CA_PATH}/certs.db" ]; then
    cp "${HOME}/certs.db" "${CA_PATH}/certs.db"
fi

# If there is a root bundle, add it
BUNDLE=
if [ -f "${CA_PATH}/root-bundle.crt" ]; then
    BUNDLE="-ca-bundle '${CA_PATH}/root-bundle.crt' \
	    -int-bundle '${CA_PATH}/sub-bundle.crt'"
fi

# Run service
exec /go/bin/cfssl serve -address=0.0.0.0 -port=8888 ${BUNDLE} \
    -config "${CA_PATH}/ca-config.json" \
    -db-config "${CA_PATH}/db-config.json" \
    -ca "${CA_PATH}/ca.pem" \
    -ca-key "${CA_PATH}/ca-key.pem"

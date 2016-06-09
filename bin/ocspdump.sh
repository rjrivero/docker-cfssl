#!/bin/sh

cd "${CA_PATH}" || exit 1

cfssl ocspdump -db-config="${CA_PATH}/db-config.json" > responses
# Fix file permissions
chmod 0600 responses

echo "OCSP responder file at ${CA_PATH}/responder"

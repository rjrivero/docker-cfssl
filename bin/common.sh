#!/bin/sh

# Copy default config, if missing
if [ ! -f "${CA_PATH}/ca-config.json" ]; then
    cp "$HOME/ca-config.json" "${CA_PATH}/ca-config.json"
fi

# Create db_config file, if it does not exist
if [ ! -f "${CA_PATH}/db-config.json" ]; then
    cp "${HOME}/db-config.json" "${CA_PATH}/db-config.json"
fi

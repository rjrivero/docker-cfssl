#!/bin/sh

if [ "x$1" = "x-root" ]; then
    cat "${HOME}/ca-csr-root.json"
else
    cat "${HOME}/ca-csr.json"
fi

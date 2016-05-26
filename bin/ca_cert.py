#!/usr/bin/env python

# Expects a json cfssl info response from stdin
# extracts the certificate to stdout

from __future__ import print_function

import json
import sys
import traceback


# Print error message to stderr
def eprint(message):
    print(message, file=sys.stderr)

# Get the name of the file where we must save the cert
if len(sys.argv) < 2:
    eprint("Usage: %s [output_filename]")
    sys.exit(-1)

# Read json data from stdin
try:
    info = json.load(sys.stdin)
except:
    eprint("Error reading json from stdin")
    traceback.print_exc(file=sys.stderr)
    sys.exit(-2)

# Write certificate to outfile
try:
    # Trigger KeyError before opening output file
    data = info['result']['certificate']
    with open(sys.argv[1], "w+") as outfile:
        outfile.write(data)
except KeyError:
    eprint("Malformed json data")
    eprint(info)
    sys.exit(-3)
except IOError:
    eprint("Could not write to output file")
    traceback.print_exc(file=sys.stderr)
    sys.exit(-4)

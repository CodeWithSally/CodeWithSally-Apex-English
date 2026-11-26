#!/bin/bash
# The bare minimum: log the Salesforce CLI in from the auth URL.
# Compare with cloud-sf-login.sh, which adds the safety checks.
echo "$SFDX_AUTH_URL" | sf org login sfdx-url --sfdx-url-stdin=- --alias cws --set-default

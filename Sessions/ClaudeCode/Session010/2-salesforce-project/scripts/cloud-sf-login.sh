#!/bin/bash
# SessionStart hook: log the Salesforce CLI in to the org at the start of a
# Claude Code cloud session. See .claude/settings.json.

# Only the cloud environment sets SFDX_AUTH_URL. Anywhere else, do nothing.
[ -z "$SFDX_AUTH_URL" ] && exit 0

# No CLI (wrong environment): say so, but never block the session.
command -v sf >/dev/null 2>&1 || { echo "Salesforce: sf not installed."; exit 0; }

ALIAS="${SF_ORG_ALIAS:-cws}"
export SF_DISABLE_DNS_CHECK=true

# Pipe the auth URL in, and discard the CLI's output: a failed login
# prints the auth URL back.
if printf '%s' "$SFDX_AUTH_URL" \
    | sf org login sfdx-url --sfdx-url-stdin=- --alias "$ALIAS" --set-default \
        >/dev/null 2>&1
then
    echo "Salesforce: logged in. Default org is '$ALIAS'."
else
    echo "Salesforce: login failed. Check SFDX_AUTH_URL and the allowed domains."
fi
exit 0

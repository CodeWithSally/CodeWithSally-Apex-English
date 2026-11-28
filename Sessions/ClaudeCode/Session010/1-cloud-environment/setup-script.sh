#!/bin/bash
# Cloud environment setup script (claude.ai/code > environment > Setup script).
# Runs as root once, before Claude starts. Later sessions start from a saved
# copy of the machine and skip it, until the script or the network settings
# change, or after about a week.
#
# It can't log in to Salesforce: the environment's variables aren't set yet
# while it runs. The login happens in the repo's SessionStart hook instead
# (see ../2-salesforce-project/.claude/settings.json).
npm install -g @salesforce/cli

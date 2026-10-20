#!/usr/bin/env bash
# Make a fresh private copy of mtoh-site for the issue-triage demo, and file the three seed issues.
# Usage: bash new-demo-repo.sh cws-session9-b
set -euo pipefail

NAME="${1:?usage: bash new-demo-repo.sh <repo-name>}"
REPO="wkuehler/$NAME"
SRC="$HOME/projects/mtoh/mtoh-site"

# 1. Create the empty private repo and push mtoh-site's main into it (a plain copy, not a fork).
gh repo create "$REPO" --private
git -C "$SRC" push "git@github.com:$REPO.git" main

# 2. Seed issues (filed before the routine points at this repo, so they don't trigger it).
gh issue create -R "$REPO" --label bug --title "Add to calendar menu runs off the right edge on phones" --body "On my phone (iPhone, Safari), tapping Add to calendar on the next-session card opens the menu, but part of it is cut off past the right edge of the screen. I have to scroll sideways to see the Outlook option. Expected: the whole menu fits on the screen."
gh issue create -R "$REPO" --label bug --title "Partner logos are different sizes in the Battle buddies section" --body "In the Battle buddies section on the home page, the partner logos don't look consistent. Some fill their white plate and others look small, so the cards feel uneven next to each other. It would look cleaner if every logo appeared at about the same visual size."
gh issue create -R "$REPO" --label enhancement --title "Calendar page should show the speaker's LinkedIn" --body "When a session has a confirmed speaker, the calendar page shows their name and organization. It would be helpful to link the speaker's name to their LinkedIn profile so attendees can learn about them before the session."

echo
echo "Done: https://github.com/$REPO"
echo "Next: give the Claude GitHub App access to $NAME (if it's limited to selected repos),"
echo "then point the Issue triage routine's repository and GitHub trigger at $REPO."

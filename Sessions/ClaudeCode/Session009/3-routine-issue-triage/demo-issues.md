# Session 9 - Issue triage demo: issue commands

Repo: `wkuehler/cws-session9-b`. If the repo is recreated under another name, change `-R` in every command.
Each command is one line. Run it with `!` in front, or paste it into any terminal.

## Seed issues (file before the call, before the routine exists)

These give the duplicate check something to compare against. Filed before the routine exists, they don't trigger it.

1. Unrelated UI bug:

```
gh issue create -R wkuehler/cws-session9-b --label bug --title "Add to calendar menu runs off the right edge on phones" --body "On my phone (iPhone, Safari), tapping Add to calendar on the next-session card opens the menu, but part of it is cut off past the right edge of the screen. I have to scroll sideways to see the Outlook option. Expected: the whole menu fits on the screen."
```

2. Overlaps the logo demo issue (should be flagged as related or a duplicate):

```
gh issue create -R wkuehler/cws-session9-b --label bug --title "Partner logos are different sizes in the Battle buddies section" --body "In the Battle buddies section on the home page, the partner logos don't look consistent. Some fill their white plate and others look small, so the cards feel uneven next to each other. It would look cleaner if every logo appeared at about the same visual size."
```

3. Feature request (tests the "not a bug" verdict):

```
gh issue create -R wkuehler/cws-session9-b --label enhancement --title "Calendar page should show the speaker's LinkedIn" --body "When a session has a confirmed speaker, the calendar page shows their name and organization. It would be helpful to link the speaker's name to their LinkedIn profile so attendees can learn about them before the session."
```

## Live demo issues (file on stream, after the routine exists)

Each one triggers the routine. About 45-60 seconds to the report.

A. **Sally's logo** - report only. Flags the overlap with seed #2; no PR, because the fix is a bigger image from Sally, not code.

```
gh issue create -R wkuehler/cws-session9-b --label bug --title "The Code with Sally logo looks tiny on the Battle buddies card" --body "On the home page, the Code with Sally logo in the Battle buddies section is much smaller than the others. It's hard to read."
```

B. **Links open in the same tab** - report plus a draft PR (`target="_blank"` on the partner links), linked to the issue under Development.

```
gh issue create -R wkuehler/cws-session9-b --label bug --title "Partner links open in the same tab and take visitors off the site" --body "In the Battle buddies section, clicking a partner link (YouTube, Website, Spotify) replaces the MTOH site in the same tab. Visitors have to hit Back to return. Partner links should open in a new tab."
```

C. **Spare: link order** - report plus a one-line draft PR. Use if A or B misbehaves, or if there's time.

```
gh issue create -R wkuehler/cws-session9-b --label bug --title "Code with Sally card lists its links in a different order" --body "In the Battle buddies section, The Military Minute card lists Website first and then YouTube, but the Code with Sally card lists YouTube first and then Website. The cards should use the same order."
```

Note: B and C both edit the same line of `pages/index.html`. Filed together, they produce two PRs that conflict. Fine for a demo; don't merge both.

# Cloud Environment: "Code with Sally Session 10 Live"

We built this environment live at **claude.ai/code**: pick the environment under the prompt box, then edit its settings. Every routine in this session runs on it, except General Request (see `../5-routine-general-request/`).

## Final settings

| Setting | Value | Why |
|---|---|---|
| Network access | **Full** | Easiest for the demo, and the riskiest choice. For real work, use **Limited** with *Allow package managers* checked, plus the Salesforce hosts below. |
| Setup script | [`setup-script.sh`](setup-script.sh), which runs `npm install -g @salesforce/cli` | Installs `sf` once. Later sessions reuse the saved machine. |
| Environment variables | `SFDX_AUTH_URL=force://PlatformCLI::<token>@<your-org>`<br>`SF_DISABLE_DNS_CHECK=true` | The org login, and a fix for the CLI's DNS lookup, which fails behind the cloud proxy ("The org cannot be found"). |
| Repository | `cws-session10-a` (the project in `../2-salesforce-project/`) | Brings the `CLAUDE.md` and the SessionStart login hook |
| Network secrets | None | Not used. They add credentials to outbound web requests, which is separate from how the Salesforce CLI logs in. |

**Hosts to allow for real work (Limited):**

```
login.salesforce.com
test.salesforce.com
*.salesforce.com
*.my.salesforce.com
*.develop.my.salesforce.com
```

## How we built it, step by step

1. **Network None.** Ask "Install the Salesforce CLI then run `sf --version`". It fails, because nothing can leave the machine.
2. **Limited + Allow package managers.** The same request works, but only in a **new** session, because a running session doesn't pick up environment changes. Claude installs `sf` itself, but the next session doesn't have it.
3. **Setup script.** Add the one-line install. A new session shows *Ran setup script*, and `sf --version` answers. Another new session skips the step: the machine is already built.
4. **`sf org list`** returns no orgs. The CLI is installed, but nothing has logged it in.
5. **Environment variables.** Paste the auth URL into `SFDX_AUTH_URL` and add `SF_DISABLE_DNS_CHECK=true`. Claude may work out how to log in by itself, but that isn't something you can count on.
6. **Connect the repo.** Its SessionStart hook runs `scripts/cloud-sf-login-simple.sh`, which pipes `SFDX_AUTH_URL` into `sf org login sfdx-url` before Claude starts.
7. **Network Full.** Under Limited with no Salesforce hosts, the hook's login was blocked. With Full, a new session lists the org.

## Making the auth URL (on your laptop)

```bash
sf org auth show-sfdx-auth-url --target-org cws --json \
  | jq -r .result.sfdxAuthUrl \
  | pbcopy        # wl-copy on Linux
```

Piping it to the clipboard keeps the token off the screen. **Never run it bare on a screenshare**, because without the pipe it prints the whole token.

> **Plain text.** Anyone who can use the environment can read its variables, and so can every command Claude runs. Use a Developer Edition org, scratch org or sandbox, never production. Better still, log in as a dedicated user that has only the access the job needs.

## If the token leaks

1. **Revoke** it: Setup → Users → the user → OAuth Connected Apps → **Revoke** next to Salesforce CLI. This signs out every CLI login for that user, your laptop included.
2. **Look** at what it did: Login History, Setup Audit Trail, Deployment Status.
3. **Reissue** it: `sf org login web --alias cws`, then run the clipboard command above again.
4. **Replace** it: paste the new URL over `SFDX_AUTH_URL` and start a new session. Sessions that are already running keep the old value.

We did this live in the session: we showed the URL on screen, then revoked it right away.

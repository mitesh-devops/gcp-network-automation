## PART A: One-time setup (do this 1–2 days before)

### A1. Prerequisites
- A Google Cloud project with billing enabled, where you are Owner
- `gcloud` CLI logged in (`gcloud auth login`), `git`, and a GitHub account
- Optional: the GitHub CLI `gh` (makes opening pull requests quicker)

### A2. Run the bootstrap script
```bash
./setup/bootstrap.sh <your-project-id>
```
Note the three values it prints at the end: region, service account and `_TF_STATE_BUCKET`.
The default region is `asia-south1`. To use a different one, pass it as the second argument and also change `region`/`zone` in `terraform/variables.tf`.

### A3. Put this folder on GitHub (as a **private** repo for now)
Create an empty **private** repository on GitHub named `gcp-network-automation`, with no README, .gitignore or license. Then:
```bash
git init
git branch -M main          # makes sure the branch is called main, not master
git add .
git commit -m "Initial commit: network as code"
git remote add origin https://github.com/<you>/gcp-network-automation.git
git push -u origin main
```
When Git asks for a password, paste a GitHub **personal access token** (fine-grained: only this repo, *Contents: Read and write*).

**Why private?** The pull request trigger runs the code in the pull request as `terraform-sa`. On a public repo, anyone could open a pull request and run their own commands with your cloud permissions. Keep the repo private until the triggers are deleted after the session, then make it public for students.

### A4. Connect GitHub to Cloud Build
Console › **Cloud Build › Repositories (2nd gen)** › **Create host connection** › GitHub, region **asia-south1**. Approve the Cloud Build GitHub App on your account and install it for this repo, then **Link repository** and pick this repo.

### A5. Create the three triggers
Console › **Cloud Build › Triggers** › region **asia-south1** (the same region as the connection) › **Create trigger**. For all three, set:
- **Repository:** the one you linked in A4 (2nd gen)
- **Configuration:** Cloud Build configuration file, with the location shown in the table below
- **Substitution variables** (under Advanced): `_TF_STATE_BUCKET` = `<project-id>-tfstate`, spelled exactly, with the leading underscore
- **Service account:** `terraform-sa@<project-id>.iam.gserviceaccount.com`, not the default Cloud Build account

| Trigger name | Event | Config file | Extra substitution |
|---|---|---|---|
| `demo-pr-preview` | Pull request, base branch `^main$` | `cloudbuild.yaml` | `_APPLY` = `false` |
| `demo-main-apply` | Push to branch `^main$` | `cloudbuild.yaml` | `_APPLY` = `true` |
| `demo-destroy` | Manual invocation, branch `main` | `cloudbuild-destroy.yaml` | none |

For `demo-pr-preview`, set **Comment control** to **"Required except for owners and collaborators"**. Your own pull requests then run automatically, while anyone else's only run after you comment `/gcbrun`. This matters most if the repo is ever public while the trigger exists.

The console warning about pull requests from anyone with read access is expected. The private repo plus this comment control setting is the answer to it.

### A6. Rehearse the whole demo once (Part B, stages 1–5)
This checks everything works, and it also makes GitHub aware of the check name needed in A7.

### A7. Protect the main branch (needed for the Guardrail demo)
GitHub › repo **Settings › Branches › Add classic branch protection rule** for `main`:
- Tick **Require status checks to pass before merging**, then search for and select the `demo-pr-preview` check.
- Leave **Do not allow bypassing the above settings** unticked, so you (the admin) can still push directly to `main` for the Provision demo.

What students will see on the bad pull request: a red ✗, and GitHub saying **merging is blocked**. As the admin you'll also see a "bypass branch protections" checkbox. That's worth pointing out: even the admin would have to deliberately override the safety check, and that override is recorded.

**If GitHub says "Rules on your private repos can't be enforced until you upgrade":** this repo lives under a GitHub Organization on the Free plan, which only enforces branch protection (classic rules and rulesets alike) on private repos for Team/Enterprise orgs. Pick one:
- **Upgrade the org to Team.** The clean fix if you'll reuse this org for future sessions.
- **Do the rehearsal under your personal account instead of the org**, on GitHub Pro (or higher) — personal accounts don't need Team/Enterprise for private-repo protection, just Pro.
- **Flip the repo to public just for A7–A8**, then back to private. The `demo-pr-preview` comment-control setting from A5 already keeps strangers from triggering builds on your credentials while it's public, so the exposure window is limited to the rehearsal. Re-check the repo visibility is back to private before the real session, per the note in A3.

### A8. Reset after rehearsal
After the rehearsal's Destroy stage, remove the HTTPS rule from `main` without triggering a build:
```bash
git pull
git rm terraform/02-modify-allow-https.tf
git commit -m "Reset demo [skip ci]"
git push
```
Also delete the rehearsal branches on GitHub. The project is now empty and ready for the day.

---

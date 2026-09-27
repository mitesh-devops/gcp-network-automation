# Cloud Network Automation on GCP: demo repo

Everything in this repo matches the slides. Humans change only Git; Cloud Build (running as `terraform-sa`) is the only thing that changes Google Cloud.

## What is in the repo, and where it appears in the slides

| File | What it is | Slide |
|---|---|---|
| `terraform/network.tf` | 1 VPC `demo-vpc` (custom mode) and 2 subnet `demo-subnet` 10.10.1.0/24 | 7, 13, 14 |
| `terraform/firewall.tf` | 3 firewall: HTTP 80 from anywhere, SSH 22 only from IAP (35.235.240.0/20) | 13, 15 |
| `terraform/route.tf` | 4 route 0.0.0.0/0 to the default internet gateway | 13, 14 |
| `terraform/vm.tf`, `startup.sh` | 5 VM `demo-web`, e2-micro, public IP, nginx web page | 13, 14 |
| `terraform/providers.tf` | Google provider and the GCS remote state backend | 8 |
| `cloudbuild.yaml` | Pipeline: 1 check (validate), 2 inspect (Checkov guardrail), 3 plan, 4 build (apply) | 10, 12 |
| `cloudbuild-destroy.yaml` | Teardown pipeline: plan the removal, then remove | 20 |
| `demo-changes/02-modify-allow-https.tf` | The Modify demo change (1 to add) | 18 |
| `demo-changes/03-guardrail-bad-open-ssh.tf` | The Guardrail demo change (gets blocked) | 19 |
| `setup/bootstrap.sh` | One-time setup: APIs, state bucket, service account | before the day |

The guardrail is Checkov rule `CKV_GCP_2` ("firewall must not allow SSH from 0.0.0.0/0"). It was tested against these exact files: the normal code and the HTTPS change pass, and the open-SSH change fails.

---

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

### A3. Put this folder on GitHub
Create an empty repository on GitHub (for example `gcp-network-automation`), then:
```bash
git init -b main
git add .
git commit -m "Initial commit: network as code"
git remote add origin https://github.com/<you>/gcp-network-automation.git
git push -u origin main
```

### A4. Connect GitHub to Cloud Build
Console › **Cloud Build › Repositories (2nd gen)** › **Create host connection** › GitHub, region **asia-south1**. Install the Cloud Build GitHub App on your account, then **Link repository** and pick this repo.

### A5. Create the three triggers
Console › **Cloud Build › Triggers** › region **asia-south1** › **Create trigger**. For all three, set:
- Repository: the one you linked in A4
- Service account: `terraform-sa@<project-id>.iam.gserviceaccount.com`
- Substitution variable `_TF_STATE_BUCKET` = `<project-id>-tfstate`

| Trigger name | Event | Config file | Extra substitution |
|---|---|---|---|
| `demo-pr-preview` | Pull request, base branch `^main$` | `cloudbuild.yaml` | `_APPLY` = `false` |
| `demo-main-apply` | Push to branch `^main$` | `cloudbuild.yaml` | `_APPLY` = `true` |
| `demo-destroy` | Manual invocation, branch `main` | `cloudbuild-destroy.yaml` | none |

### A6. Rehearse the whole demo once (Part B, stages 1–5)
This checks everything works, and it also makes GitHub aware of the check name needed in A7.

### A7. Protect the main branch (needed for the Guardrail demo)
GitHub › repo **Settings › Branches › Add classic branch protection rule** for `main`:
- Tick **Require status checks to pass before merging**, then search for and select the `demo-pr-preview` check.
- Leave **Do not allow bypassing the above settings** unticked, so you (the admin) can still push directly to `main` for the Provision demo.

What students will see on the bad pull request: a red ✗, and GitHub saying **merging is blocked**. As the admin you'll also see a "bypass branch protections" checkbox. That's worth pointing out: even the admin would have to deliberately override the safety check, and that override is recorded.

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

## PART B: The live demo (same order as the slides)

Before you start, open these tabs: the GitHub repo, **Cloud Build › History** (region asia-south1), **VPC network › VPC networks**, and a blank tab for the website.

### Stage 1: Provision (slide 17) — "one push builds the network"
Show the files in `terraform/`. Then make one small real change and push it. For example, edit the `<h1>` line in `terraform/startup.sh` to say `Hello, Nirma University!`:
```bash
git add terraform/startup.sh
git commit -m "Provision the demo network"
git push
```
- Cloud Build › History: `demo-main-apply` runs steps 0-init › 1-check › 2-inspect-guardrail › 3-plan › 4-build-apply.
- In the plan log: **Plan: 6 to add** (VPC, subnet, 2 firewall rules, route, VM).
- The apply log creates them VPC first and the VM last, and prints `website_url` at the end.
- Wait about 60–90 seconds for nginx to install, then open `website_url` in the browser.

The first build takes a few minutes because it downloads Terraform, Checkov and the Google provider. For a push without a code change, use `git commit --allow-empty -m "Provision"`.

### Stage 2: Modify (slide 18) — "change the network with a pull request"
```bash
git checkout -b add-https
cp demo-changes/02-modify-allow-https.tf terraform/
git add terraform/02-modify-allow-https.tf
git commit -m "Allow HTTPS (port 443)"
git push -u origin add-https
gh pr create --fill        # or open the pull request on github.com
```
- On the pull request, the `demo-pr-preview` check runs. Click **Details** › view the log for step `3-plan`: **Plan: 1 to add, 0 to change, 0 to destroy**. Step 4 prints "preview only".
- Merge the pull request › `demo-main-apply` runs › the `demo-allow-https` rule appears. Nothing else changes.

(The rule only opens port 443; nginx isn't set up for HTTPS, so the website itself doesn't change. The point is the safe change process.)

### Stage 3: Guardrail (slide 19) — "a bad change gets blocked"
```bash
git checkout main && git pull
git checkout -b open-ssh-to-world
cp demo-changes/03-guardrail-bad-open-ssh.tf terraform/
git add terraform/03-guardrail-bad-open-ssh.tf
git commit -m "Quick fix: open SSH to everyone"
git push -u origin open-ssh-to-world
gh pr create --fill
```
- Step `2-inspect-guardrail` **fails** with `CKV_GCP_2 ... FAILED for resource: google_compute_firewall.allow_ssh_anywhere`.
- Steps 3 and 4 never run. The pull request shows the failed check and **merging is blocked**.
- Close the pull request without merging. Nothing reached the cloud.

### Stage 4: Destroy (slide 20) — "tear it all down through the pipeline"
```bash
git checkout main && git pull
gcloud builds triggers run demo-destroy --region=asia-south1 --branch=main
```
(Or Cloud Build › Triggers › `demo-destroy` › **Run**.)
- Step `1-plan-destroy`: **Plan: 0 to add, 0 to change, 7 to destroy** (6 resources plus the HTTPS rule).
- Removal happens in reverse: the VM first, the VPC last. Refresh the website tab: it's gone.

### Stage 5: Observe (slide 21) — "every action leaves a trail"
1. **Build history:** Cloud Build › History shows every run from today, green and red, each linked to its commit.
2. **Audit logs:** Logging › Logs Explorer, paste this query and run it:
   ```
   logName:"cloudaudit.googleapis.com%2Factivity"
   protoPayload.authenticationInfo.principalEmail="terraform-sa@<project-id>.iam.gserviceaccount.com"
   ```
   Every create and delete was done by the robot's service account, not by a person.
3. **State versions:** one version of the state file per change:
   ```bash
   gcloud storage ls --all-versions gs://<project-id>-tfstate/network/
   ```

### Optional: show the admin SSH lane from slide 15 (while the VM exists)
```bash
gcloud compute ssh demo-web --zone=asia-south1-a --tunnel-through-iap
```
This works because the firewall allows port 22 from Google IAP only.

---

## After the session
- The Destroy stage already removed all network resources.
- Optionally run `./setup/cleanup-after-session.sh <project-id>` to delete the state bucket and service account, then delete the three triggers and the GitHub connection in the console.

## Troubleshooting
- **Build fails at `0-init` with a permission error:** check the trigger uses `terraform-sa` and that `_TF_STATE_BUCKET` is spelled exactly `<project-id>-tfstate`.
- **"Error acquiring the state lock":** two builds ran at once. Wait for the first to finish and re-run.
- **Website doesn't load:** wait another minute (nginx is still installing), and make sure you used `http://`, not `https://`.
- **`demo-pr-preview` not listed in branch protection:** it only appears after it has run once on a pull request (step A6).

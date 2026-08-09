# GitHub Branch Protection Configuration Guide

This document defines the required GitHub branch protection rule configuration for `main` to enforce release safety gates.

---

## 1. Branch Protection Rules for `main`

Navigate to **GitHub Repository Settings** -> **Branches** -> **Add branch protection rule**:

- **Branch name pattern**: `main`

### Required Checks & Policies

1. **Require a pull request before merging**:
   - Required approvals: `1`
   - Dismiss stale pull request approvals when new commits are pushed: `Checked`
   - Require review from Code Owners: `Checked`

2. **Require status checks to pass before merging**:
   - Require branches to be up to date before merging: `Checked`
   - Required Status Checks:
     - `Code Formatting & Static Analysis`
     - `Flutter Unit, Widget & Coverage Tests`
     - `Node Serverless Function Tests`
     - `Appwrite Permission Invariants & Schema Drift`
     - `Web Release Build & Budget`
     - `Android APK Release Build & Budget`
     - `Verify Release Artifact Integrity`
     - `Secret Scanning (Gitleaks)`
     - `OSV Vulnerability Scan`
     - `CodeQL Analysis`

3. **Require conversation resolution before merging**: `Checked`
4. **Require signed commits**: `Checked` (Recommended)
5. **Do not allow bypassing the above settings**: `Checked`
6. **Restrict who can push to matching branches**: `Checked` (Only repository administrators)
7. **Allow force pushes**: `Disabled`
8. **Allow deletions**: `Disabled`

---

## 2. GitHub CLI Automated Protection Command

If executing via GitHub CLI with repository admin credentials:

```bash
gh api \
  --method PUT \
  -H "Accept: application/vnd.github+json" \
  /repos/Kh3rwa1/olitunapp/branches/main/protection \
  -f required_status_checks[strict]=true \
  -f required_status_checks[contexts][]="Code Formatting & Static Analysis" \
  -f required_status_checks[contexts][]="Flutter Unit, Widget & Coverage Tests" \
  -f required_status_checks[contexts][]="Node Serverless Function Tests" \
  -f required_status_checks[contexts][]="Appwrite Permission Invariants & Schema Drift" \
  -f required_status_checks[contexts][]="Web Release Build & Budget" \
  -f required_status_checks[contexts][]="Android APK Release Build & Budget" \
  -f required_status_checks[contexts][]="Verify Release Artifact Integrity" \
  -f required_status_checks[contexts][]="Secret Scanning (Gitleaks)" \
  -f required_status_checks[contexts][]="OSV Vulnerability Scan" \
  -f required_status_checks[contexts][]="CodeQL Analysis" \
  -f enforce_admins=true \
  -f required_pull_request_reviews[required_approving_review_count]=1 \
  -f required_pull_request_reviews[dismiss_stale_reviews]=true \
  -f restrictions=null
```

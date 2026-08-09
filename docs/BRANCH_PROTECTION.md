# Branch Protection Policy and GitHub API Configuration

## Target Branch: `main`

### Protection Rules Summary
- **Require Pull Request**: All changes must be submitted via Pull Request.
- **Required Approvals**: Minimum 1 approving review from a code owner / maintainer.
- **Dismiss Stale Approvals**: Approvals are automatically dismissed when new commits are pushed.
- **Require Conversation Resolution**: All review threads must be resolved before merging.
- **Strict Status Checks**: Branches must be up-to-date before merging.
- **Required Status Checks**:
  - `Release Gate`
  - `Security Gate`
- **Enforce Administrators**: `enforce_admins = true` (administrators cannot bypass restrictions).
- **Require Linear History**: Direct merge commits disabled (squash or rebase required).
- **Prevent Force Pushes**: `allow_force_pushes = false`.
- **Prevent Branch Deletion**: `allow_deletions = false`.

### GitHub REST API Configuration Command

```bash
gh api -X PUT repos/Kh3rwa1/olitunapp/branches/main/protection \
  -H "Accept: application/vnd.github+json" \
  -F "required_status_checks[strict]=true" \
  -F "required_status_checks[contexts][]=Release Gate" \
  -F "required_status_checks[contexts][]=Security Gate" \
  -F "enforce_admins=true" \
  -F "required_pull_request_reviews[dismiss_stale_reviews]=true" \
  -F "required_pull_request_reviews[require_code_owner_reviews]=true" \
  -F "required_pull_request_reviews[required_approving_review_count]=1" \
  -F "required_conversation_resolution=true" \
  -F "required_linear_history=true" \
  -F "allow_force_pushes=false" \
  -F "allow_deletions=false"
```

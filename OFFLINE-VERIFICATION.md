# Offline verification boundary

Preserve shared references/scripts/config examples on repeated additive deploy.

## Reproduce

`python3 -m unittest discover -s tests -v`

Shared components have one upstream (heisenberg-team) and pinned content digests. Refresh both reviewed manifests together, never auto-copy agent/model defaults. No native uninstall exists; fixture rollback is snapshot restore. --force needs an operator-owned complete snapshot.

## Rollback

Review the commit diff and use a new checkout of the pre-change commit for source rollback. Keep user data and live installations untouched. A source rollback is not permission to restore unsafe network exposure or bypass approval.

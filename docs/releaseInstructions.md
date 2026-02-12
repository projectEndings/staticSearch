# Dev Build and Release Automation

Pushes to `dev` now run an automated GitHub Actions workflow (`.github/workflows/dev-release.yml`) which:

1. Reads `EDITION`, parses semantic versioning (`X.Y.Z`), and increments the patch number (`Z + 1`).
1. Updates `EDITION` on `dev` with the new version and commits that change automatically.
1. Runs the project build and tests (`ant -f build.xml test`).
1. Builds release archives (`ant -f buildRelease.xml all`).
1. Creates and pushes a Git tag in the form `vX.Y.Z`.
1. Creates a GitHub prerelease with generated notes and attached `dist/*.zip` and `dist/*.tar.gz` artifacts.

For testing the workflow itself, pushes to `feature/dev-release-ci-fix` (or manual `workflow_dispatch`) run the same build steps without committing, tagging, or creating releases.

## Notes

- The workflow is `dev`-only.
- `EDITION` should remain semantic-version compatible (`major.minor.patch`).
- Legacy values like `2.0.1beta` are accepted as input for bumping, but output is normalized to strict semver (`2.0.2`).
- GitHub Pages deployment will be handled in a separate workflow step later.

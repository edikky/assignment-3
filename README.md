# Assignment 3: CI/CD with GitHub Actions

A Bash application with linting, tests and a Docker image, validated by a GitHub Actions pipeline.

## Setup

```bash
git clone <your-repository-url>
cd assignment-3
chmod +x grade.sh app/*.sh scripts/*.sh tests/*.sh
```

## Usage

```bash
./app/app.sh system-info
./app/app.sh check-host <host>
./app/app.sh check-port <host> <port>
./app/app.sh help
```

Exit codes: `0` success, `1` runtime failure, `2` invalid command or input.

## Testing

```bash
./scripts/lint.sh     # required files + bash -n (ShellCheck if installed)
./tests/test.sh       # 12 tests
./scripts/build.sh    # builds the image and runs smoke tests
./grade.sh            # full local grader
```

## Docker

```bash
docker build -t devops-tool .
docker run --rm devops-tool help
docker run --rm devops-tool system-info
docker compose run --rm app system-info
```

## CI pipeline

`.github/workflows/ci.yml` runs on every push and pull request:

validate (lint) → test (`tests/test.sh`) → docker (`scripts/build.sh`)

The jobs are chained with `needs:`, so a failure stops the later jobs.

## CI failure demonstration

1. Created branch `demo/ci-failure` and added a syntax error to `app/app.sh`.
2. Pushed it. The `validate` job failed, and `test` and `docker` were skipped: [link to failed run].
3. Reverted the change and pushed again. All three jobs passed: [link to passing run].
4. Merged the branch back into `main`. The final workflow on `main` passes.

## Notes for graders

After cloning, only `main` exists locally. To see the feature branch locally:

```bash
git branch feature/ci-pipeline origin/feature/ci-pipeline
```

## Assumptions

- Linux environment with Bash, and Docker installed for the Docker checks.
- `check-host` needs name resolution to work. `check-port` needs `/dev/tcp` support (standard in Bash).
Docker Github Actions Runner
============================

[Forked from](https://hub.docker.com/r/myoung34/github-runner)

Allows to run Github Actions on Docker Containers (modified with Cotalker stack).

### How to run ###

```
# Download Repo
git clone git@github.com:Cotalker/github-actions-runner-base-linux.git
# Build image
docker build . -t cotalker-github-runner:latest
# Run Container
docker run -d --restart always --name github-runner \
  -e RUNNER_NAME_PREFIX="<runner name>" \
  -e RUNNER_TOKEN="<go to [this link](https://github.com/organizations/Cotalker/settings/actions/add-new-runner) and retrieve the token argument>" \
  -e RUNNER_WORKDIR="/tmp/github-runner" \
  -e ORG_RUNNER="true" \
  -e ORG_NAME="Cotalker" \
  -e LABELS="<nombre usuario>" \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /tmp/github-runner:/tmp/github-runner \
  cotalker-github-runner:latest

```

## Original documentation ##
[Use this link](./README_ORIGINAL.md)

Docker Github Actions Runner
============================

[Forked from](https://hub.docker.com/r/myoung34/github-runner)

Allows to run Github Actions on Docker Containers (modified with Cotalker stack).

## How to run ##

### Download and Build  
```
git clone git@github.com:Cotalker/github-actions-runner-base-linux.git
docker build . -t cotalker-github-runner:latest
```

### Run Container  
*  __runner-name__ : any string
*  __user-name__: any string 
*  __token__ : go to [this link](https://github.com/organizations/Cotalker/settings/actions/add-new-runner) and retrieve the token argument from the url in the example
```
docker run -d --restart always --name github-runner \
  -e RUNNER_NAME_PREFIX="<runner-name>" \
  -e RUNNER_TOKEN="<token>" \
  -e RUNNER_WORKDIR="/tmp/github-runner" \
  -e ORG_RUNNER="true" \
  -e ORG_NAME="Cotalker" \
  -e LABELS="<user-name>" \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /tmp/github-runner:/tmp/github-runner \
  336102453294.dkr.ecr.us-east-1.amazonaws.com/cotalker-github-actions:latest
```

## Original documentation ##
[Use this link](./README_ORIGINAL.md)

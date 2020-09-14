# hadolint ignore=DL3007
FROM myoung34/github-runner-base:latest
LABEL maintainer="myoung34@my.apsu.edu"

ARG GH_RUNNER_VERSION="2.273.2"
ARG TARGETPLATFORM

### COTALKER ADD-ONS
RUN apt update && apt upgrade -y
RUN apt install wget
RUN wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.33.8/install.sh | bash
RUN export NVM_DIR="$HOME/.nvm"
RUN bash "$NVM_DIR/nvm.sh"
### END COTALKER ADD-ONS

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

WORKDIR /actions-runner
COPY install_actions.sh /actions-runner

RUN chmod +x /actions-runner/install_actions.sh \
  && /actions-runner/install_actions.sh ${GH_RUNNER_VERSION} ${TARGETPLATFORM} \
  && rm /actions-runner/install_actions.sh

COPY token.sh /
RUN chmod +x /token.sh

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

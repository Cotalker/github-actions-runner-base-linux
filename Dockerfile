FROM ubuntu:20.04
ARG GIT_VERSION="2.26.2"
ENV DOCKER_COMPOSE_VERSION="1.26.2"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV DEBIAN_FRONTEND=noninteractive
# hadolint ignore=DL3003
RUN apt-get update && \
  apt-get install -y --no-install-recommends \
    awscli \
    curl \
    tar \
    unzip \
    apt-transport-https \
    ca-certificates \
    sudo \
    gnupg-agent \
    software-properties-common \
    build-essential \
    zlib1g-dev \
    gettext \
    liblttng-ust0 \
    libcurl4-openssl-dev \
    inetutils-ping \
    jq \
    rsync \
  && c_rehash \
  && cd /tmp \
  && curl -sL https://www.kernel.org/pub/software/scm/git/git-${GIT_VERSION}.tar.gz -o git.tgz \
  && tar zxf git.tgz \
  && cd git-${GIT_VERSION} \
  && ./configure --prefix=/usr \
  && make \
  && make install \
  && cd / \
  && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - \
  && [[ $(lsb_release -cs) == "eoan" ]] && ( add-apt-repository "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/ubuntu disco stable" ) || ( add-apt-repository "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" ) \
  && apt-get update \
  && apt-get install -y docker-ce docker-ce-cli containerd.io --no-install-recommends \
  && curl -sL "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose \
  && chmod +x /usr/local/bin/docker-compose \
  && rm -rf /var/lib/apt/lists/* \
  && rm -rf /tmp/*

ARG GH_RUNNER_VERSION="2.273.2"
ARG TARGETPLATFORM

### COTALKER ADDONS ###

## NODE 14 ##
RUN curl -sL https://deb.nodesource.com/setup_14.x | sudo bash -
RUN apt-get update && apt-get install nodejs -y
## END NODE 14 ##

## ANDROID ##
## Set timezone to UTC by default
RUN ln -sf /usr/share/zoneinfo/Etc/UTC /etc/localtime

## Use unicode
RUN apt-get update && apt-get -y install locales && \
    locale-gen en_US.UTF-8 || true
ENV LANG=en_US.UTF-8

## Install dependencies
RUN apt-get update && apt-get install --no-install-recommends -y \
  openjdk-11-jdk \
  git \
  wget \
  build-essential \
  zlib1g-dev \
  libssl-dev \
  libreadline-dev \
  unzip \
  ssh \
  # Fastlane plugins dependencies
  # - fastlane-plugin-badge (curb)
  libcurl4 libcurl4-openssl-dev

## Clean dependencies
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/*

## Install rbenv
ENV RBENV_ROOT "/root/.rbenv"
RUN git clone https://github.com/rbenv/rbenv.git $RBENV_ROOT
ENV PATH "$PATH:$RBENV_ROOT/bin"
ENV PATH "$PATH:$RBENV_ROOT/shims"

# Install ruby-build (rbenv plugin)
RUN mkdir -p "$RBENV_ROOT"/plugins
RUN git clone https://github.com/rbenv/ruby-build.git "$RBENV_ROOT"/plugins/ruby-build

# Install default ruby env
RUN echo “install: --no-document” > ~/.gemrc
ENV RUBY_CONFIGURE_OPTS=--disable-install-doc
RUN rbenv install 2.7.0
RUN rbenv global 2.7.0
RUN gem install bundler:2.1.4

# Install Google Cloud CLI
ARG gcloud=false
ARG gcloud_url=https://dl.google.com/dl/cloudsdk/release/google-cloud-sdk.tar.gz
ARG gcloud_home=/usr/local/gcloud
ARG gcloud_install_script=${gcloud_home}/google-cloud-sdk/install.sh
ARG gcloud_bin=${gcloud_home}/google-cloud-sdk/bin
ENV PATH=${gcloud_bin}:${PATH}
RUN if [ "$gcloud" = true ] ; \
  then \
    echo "Installing GCloud SDK"; \
    apt-get update && apt-get install --no-install-recommends -y \
      gcc \
      python3 \
      python3-dev \
      python3-setuptools \
      python3-pip && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    mkdir -p ${gcloud_home} && \
    wget --quiet --output-document=/tmp/gcloud-sdk.tar.gz ${gcloud_url} && \
    tar -C ${gcloud_home} -xvf /tmp/gcloud-sdk.tar.gz && \
    ${gcloud_install_script} && \
    pip3 uninstall crcmod && \
    pip3 install --no-cache-dir -U crcmod; \
  else \
    echo "Skipping GCloud SDK installation"; \
  fi

## Install Android SDK
ARG sdk_version=commandlinetools-linux-6200805_latest.zip
ARG android_home=/opt/android/sdk
ARG android_api=android-28
ARG android_build_tools=28.0.3
ARG android_ndk=true
ARG ndk_version=20.0.5594570
ARG cmake=3.10.2.4988404
RUN mkdir -p ${android_home} && \
    wget --quiet --output-document=/tmp/${sdk_version} https://dl.google.com/android/repository/${sdk_version} && \
    unzip -q /tmp/${sdk_version} -d ${android_home} && \
    rm /tmp/${sdk_version}

# Set environmental variables
ENV ANDROID_HOME ${android_home}
ENV PATH=${ANDROID_HOME}/emulator:${ANDROID_HOME}/tools:${ANDROID_HOME}/tools/bin:${ANDROID_HOME}/platform-tools:${PATH}

RUN mkdir ~/.android && echo '### User Sources for Android SDK Manager' > ~/.android/repositories.cfg

RUN echo "y" | sdkmanager --sdk_root=$ANDROID_HOME --licenses
RUN echo "y" | sdkmanager --sdk_root=$ANDROID_HOME --install \
  "platform-tools" \
  "build-tools;${android_build_tools}" \
  "platforms;${android_api}"
RUN if [ "$android_ndk" = true ] ; \
  then \
    echo "Installing Android NDK ($ndk_version, cmake: $cmake)"; \
    echo "y" | sdkmanager --sdk_root="$ANDROID_HOME" --install \
    "ndk;${ndk_version}" \
    "cmake;${cmake}" ; \
  else \
    echo "Skipping NDK installation"; \
  fi
## END ANDROID ##

### END COTALKER ADD-ONS ###

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

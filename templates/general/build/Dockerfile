FROM ubuntu:24.04

ARG GO_VERSION=1.20.2

SHELL ["/bin/bash", "-c"]

RUN apt-get update && \
	DEBIAN_FRONTEND="noninteractive" apt-get upgrade --yes

# Setup Docker repository
RUN DEBIAN_FRONTEND="noninteractive" apt-get install --yes \
		ca-certificates \
    curl \
    gnupg \
    lsb-release && \
	mkdir -m 0755 -p /etc/apt/keyrings && \
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
	echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list && \
	apt-get update

# Install baseline packages
RUN DEBIAN_FRONTEND="noninteractive" apt-get install --yes \
		bash \
		bind9-dnsutils \
		build-essential \
		ca-certificates \
		cmake \
		containerd.io \
		curl \
		docker-ce \
		docker-ce-cli \
		docker-compose-plugin \
		graphviz \
		htop \
		inetutils-tools \
		iproute2 \
		iputils-ping \
		iputils-tracepath \
		libxtst6 \
    libxrender1 \
    libfontconfig1 \
    libxi6 \
    libgtk-3-0 \
		locales \
		man \
		openssl \
		pkg-config \
		python3 \
		python3-pip \
		python3-venv \
		shellcheck \
		software-properties-common \
		sudo \
		systemd \
		systemd-sysv \
		unzip \
		vim \
		wget \
		rsync && \
	# Install latest Git using their official PPA
	add-apt-repository ppa:git-core/ppa && \
	DEBIAN_FRONTEND="noninteractive" apt-get install --yes git && \
	apt-get clean

# Enables Docker starting with systemd
RUN systemctl enable docker

# Install Python Poetry and Pipx
ENV POETRY_HOME=/opt/poetry
RUN curl -sSL https://install.python-poetry.org | python3 - && \
	python3 -m pip install pipx && \
	python3 -m pipx ensurepath

# Install Go
RUN curl -sSL -o /usr/local/go.tar.gz "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" && \
	tar -C /usr/local -xzf /usr/local/go.tar.gz && \
	rm /usr/local/go.tar.gz

# Install NodeJS
RUN curl -sL https://deb.nodesource.com/setup_lts.x | bash - && \
	apt-get update && \
	DEBIAN_FRONTEND="noninteractive" apt-get install --yes nodejs
RUN curl -sS -o - https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor -o /etc/apt/keyrings/yarn.gpg && \
	echo "deb [signed-by=/etc/apt/keyrings/yarn.gpg] https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list && \
	apt-get update && \
	DEBIAN_FRONTEND="noninteractive" apt-get install --yes yarn

# Install Rust
ENV RUSTUP_HOME=/opt/rustup
ENV CARGO_HOME=/opt/cargo
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --no-modify-path --profile minimal --default-toolchain stable --default-host x86_64-unknown-linux-gnu -y && \
	chmod -R a+w ${RUSTUP_HOME} ${CARGO_HOME}

# Make typing unicode characters in the terminal work.
ENV LANG en_US.UTF-8

# Add a user so that you're not developing as the `root` user
ARG USER=coder
RUN useradd --groups sudo,docker --create-home --shell /bin/bash --uid 1000 --user-group ${USER} \
	&& echo "${USER} ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/${USER} \
	&& chmod 0440 /etc/sudoers.d/${USER}

USER ${USER}
WORKDIR /home/${USER}

# Setup environment variables
ENV GOROOT=/usr/local/go
ENV GOPATH=/home/${USER}/go
ENV GOBIN=${GOPATH}/bin
ENV PATH=$PATH:${GOROOT}/bin:${GOBIN}:/home/${USER}/.local/bin:${POETRY_HOME}/bin:${CARGO_HOME}/bin

FROM jenkins/jenkins:lts-jdk21

USER root

ARG KUBECTL_VERSION=stable

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    maven \
    docker.io && \
    rm -rf /var/lib/apt/lists/*

RUN set -eux; \
        if [ "${KUBECTL_VERSION}" = "stable" ] || [ "${KUBECTL_VERSION}" = "latest" ]; then \
            RESOLVED_KUBECTL_VERSION="$(curl -fsSL https://dl.k8s.io/release/stable.txt)"; \
        elif echo "${KUBECTL_VERSION}" | grep -Eq '^v[0-9]+'; then \
            RESOLVED_KUBECTL_VERSION="${KUBECTL_VERSION}"; \
        else \
            RESOLVED_KUBECTL_VERSION="v${KUBECTL_VERSION}"; \
        fi; \
        curl -fsSL "https://dl.k8s.io/release/${RESOLVED_KUBECTL_VERSION}/bin/linux/amd64/kubectl" -o /usr/local/bin/kubectl && \
    chmod +x /usr/local/bin/kubectl

COPY --chown=jenkins:jenkins plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt

RUN install -d -m 0755 /var/jenkins_home/casc_configs /var/jenkins_home/.kube

EXPOSE 8080 50000

FROM semaphoreui/semaphore:latest

# Install additional packages
USER root
RUN apk add --no-cache \
    git \
    openssh-client \
    opentofu \
    ansible \
    python3 \
    py3-pip \
    curl \
    wget \
    unzip

# Create log directories
RUN mkdir -p /var/log/semaphore && \
    chown -R semaphore:semaphore /var/log/semaphore

USER semaphore

EXPOSE 3000

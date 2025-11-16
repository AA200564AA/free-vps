FROM ubuntu:24.04

# Install essential packages + SSH
RUN apt-get update && apt-get install -y \
    openssh-server \
    wget \
    net-tools \
    sudo && \
    mkdir /var/run/sshd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Hardcode root password (CHANGE THIS AFTER TESTING!)
RUN echo 'root:12345' | chpasswd

# Expose SSH port
EXPOSE 22

# Start SSH daemon and keep container alive
CMD service ssh start && tail -f /dev/null

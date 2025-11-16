FROM ubuntu:latest

# Install essential packages + SSH + autossh
RUN apt-get update && apt-get install -y openssh-server autossh wget net-tools sudo && \
    mkdir /var/run/sshd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Set root password from env var (will be set at runtime)
RUN echo 'root:$ROOT_PASSWORD' | chpasswd

# Expose SSH port (though tunneled)
EXPOSE 22

# Start SSH and the reverse tunnel with autossh for reconnection
CMD service ssh start && autossh -M 0 -o "ServerAliveInterval 30" -o "ServerAliveCountMax 3" -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" -R 0:localhost:22 nokey@localhost.run

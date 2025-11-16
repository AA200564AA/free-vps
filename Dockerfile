FROM ubuntu:latest

# تثبيت الحزم الأساسية + SSH + curl
RUN apt-get update && apt-get install -y openssh-server curl wget net-tools sudo && \
    mkdir /var/run/sshd && \
    echo 'root:12345' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# تثبيت Cloudflared
RUN curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb -o cloudflared.deb && \
    dpkg -i cloudflared.deb && rm cloudflared.deb

# نسخ ملفات config و credentials
COPY config.yml /etc/cloudflared/config.yml
COPY credentials.json /etc/cloudflared/credentials.json

# تشغيل SSH + Cloudflare Tunnel
CMD service ssh start && cloudflared tunnel run mytunnel

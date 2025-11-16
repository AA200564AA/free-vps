FROM ubuntu:latest

# Install essentials + create dirs
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        openssh-server curl wget net-tools sudo python3 && \
    mkdir -p /var/run/sshd /var/lib/tailscale /www && \
    echo 'root:12345' | chpasswd && \
    useradd -m -s /bin/bash user && \
    echo 'user:12345' | chpasswd && \
    usermod -aG sudo user && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
    sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Tailscale
RUN curl -fsSL https://tailscale.com/install.sh | sh

# Keep-alive page (prevents Railway suspension)
RUN echo '<!DOCTYPE html><html><head><title>Keep-Alive ✓</title><meta charset="utf-8">' > /www/index.html && \
    echo '<style>body{font-family:system-ui;text-align:center;padding:50px;background:#0d1117;color:#fff}</style></head><body>' >> /www/index.html && \
    echo '<h1>✅ Tailscale VPS Active</h1>' >> /www/index.html && \
    echo '<p>This keeps Railway from suspending. Copy URL from dashboard → Domains and add to UptimeRobot (every 5 min).</p>' >> /www/index.html && \
    echo '<hr><small>Tailscale IP in logs/MOTD</small></body></html>' >> /www/index.html

ENV TS_STATE_DIR=/var/lib/tailscale

# Startup script (fixes quoting, adds web server, no errors)
RUN echo '#!/bin/bash' > /start.sh && \
    echo 'tailscaled --tun=userspace-networking --state=${TS_STATE_DIR}/tailscaled.state --socket=/var/run/tailscale/tailscaled.sock &' >> /start.sh && \
    echo 'sleep 10' >> /start.sh && \
    echo 'tailscale up --authkey=${TS_AUTHKEY} --hostname=railway-vps --accept-dns=false --accept-risk=all --reset' >> /start.sh && \
    echo 'TS_IP=$(tailscale ip -4)' >> /start.sh && \
    echo 'echo "================================================================="' >> /start.sh && \
    echo 'echo "=================== TAILSCALE VPS READY ========================="' >> /start.sh && \
    echo 'echo "Tailscale IP      : $TS_IP"' >> /start.sh && \
    echo 'echo "SSH command       : ssh root@$TS_IP   (password: 12345)"' >> /start.sh && \
    echo 'echo "Keep-alive URL    : Check Railway dashboard → Domains → copy .up.railway.app URL"' >> /start.sh && \
    echo 'echo "                  Add to UptimeRobot every 5 min → never shuts down"' >> /start.sh && \
    echo 'echo "================================================================="' >> /start.sh && \
    echo 'echo "Tailscale IP: $TS_IP" > /etc/motd' >> /start.sh && \
    echo 'echo "SSH: ssh root@$TS_IP (pw 12345)" >> /etc/motd' >> /start.sh && \
    echo 'echo "Keep-alive: copy URL from Railway → Domains & ping with UptimeRobot" >> /etc/motd' >> /start.sh && \
    echo "echo 'export PS1=\"\\[\e[32m\\]\\u@\$TS_IP \\[\e[34m\\]\\w\\[\e[m\\] \\$ \"' >> /root/.bashrc" >> /start.sh && \
    echo "cp /root/.bashrc /home/user/.bashrc && chown user:user /home/user/.bashrc" >> /start.sh && \
    echo "python3 -m http.server \${PORT:-8080} --directory /www --bind 0.0.0.0 &" >> /start.sh && \
    echo 'exec /usr/sbin/sshd -D' >> /start.sh && \
    chmod +x /start.sh

CMD ["/start.sh"]

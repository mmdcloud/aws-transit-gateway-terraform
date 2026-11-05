#!/bin/bash
set -e

# Log all output
exec > >(tee -a /var/log/nva-bootstrap.log) 2>&1
echo "=== Starting Suricata NVA Appliance Bootstrap ==="

# 1. Configure Linux Kernel for Packet Forwarding
echo "Configuring Linux Kernel for Packet Forwarding..."
cat << 'EOF' > /etc/sysctl.d/99-nva.conf
net.ipv4.ip_forward = 1
net.ipv4.conf.all.forwarding = 1
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.rp_filter = 0
net.ipv4.conf.default.rp_filter = 0
EOF
sysctl -p /etc/sysctl.d/99-nva.conf

# 2. Update and install Suricata & networking utilities
echo "Updating packages and installing Suricata..."
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y suricata iptables-persistent net-tools jq tcpdump

# 3. Configure iptables for stateful packet forwarding
echo "Configuring iptables stateful forwarding..."
# Accept established/related traffic
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
# Log new connections for auditability in dmesg/syslog
iptables -A FORWARD -m conntrack --ctstate NEW -j LOG --log-prefix "[NVA-FW-FORWARD] " --log-level 4
# Forward all traffic
iptables -A FORWARD -j ACCEPT

# Save iptables rules across reboots
netfilter-persistent save

# 4. Configure Suricata IDS/IPS
echo "Configuring Suricata IDS/IPS..."
PRIMARY_IFACE=$(ip -o -4 route show to default | awk '{print $5}' | head -n1)
if [ -z "$PRIMARY_IFACE" ]; then
    PRIMARY_IFACE="eth0"
fi
echo "Primary interface detected: $PRIMARY_IFACE"

# Adjust Suricata interface
sed -i "s/interface: eth0/interface: $PRIMARY_IFACE/g" /etc/suricata/suricata.yaml

# Download latest community threat signatures
suricata-update || true

# Enable and start Suricata
systemctl enable suricata
systemctl restart suricata

# 5. Ensure Amazon SSM Agent is active
systemctl enable --now snap.amazon-ssm-agent.amazon-ssm-agent.service || true

# 6. Status check helper script
cat << 'EOF' > /usr/local/bin/check-nva.sh
#!/bin/bash
echo "=========================================="
echo "   Suricata NVA Appliance Status"
echo "=========================================="
echo "IP Forwarding: $(cat /proc/sys/net/ipv4/ip_forward)"
echo "Suricata Service: $(systemctl is-active suricata)"
echo ""
echo "--- Recent Suricata IDS/IPS Alerts (/var/log/suricata/fast.log) ---"
if [ -f /var/log/suricata/fast.log ] && [ -s /var/log/suricata/fast.log ]; then
    tail -n 15 /var/log/suricata/fast.log
else
    echo "No threat alerts detected yet. Suricata is monitoring in clean state."
fi
echo ""
echo "--- Recent Forwarded Connections (iptables) ---"
dmesg | grep "NVA-FW-FORWARD" | tail -n 10 || echo "None logged yet."
echo "=========================================="
EOF
chmod +x /usr/local/bin/check-nva.sh

echo "=== Suricata NVA Appliance Bootstrap Complete ==="


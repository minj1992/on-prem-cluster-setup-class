#!/bin/bash

# Set ubuntu password
echo "ubuntu:Login%12345" | sudo chpasswd

# Find and replace ALL PasswordAuthentication no in /etc/ssh
sudo grep -Rl "PasswordAuthentication no" /etc/ssh | sudo xargs sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g'
sudo grep -Rl "#PasswordAuthentication no" /etc/ssh | sudo xargs sed -i 's/#PasswordAuthentication no/PasswordAuthentication yes/g'

# Ensure PAM is enabled
sudo sed -i 's/^#UsePAM no/UsePAM yes/' /etc/ssh/sshd_config
sudo sed -i 's/^UsePAM no/UsePAM yes/' /etc/ssh/sshd_config

# Restart SSH service
sudo systemctl restart sshd

##############################################################################################use below script in case above not working================================

#!/bin/bash

set -e

echo "========== Configuring SSH Password Login =========="

# Ensure running as root
if [ "$EUID" -ne 0 ]; then
    echo "Run as root or with sudo."
    exit 1
fi

USERNAME="ubuntu"
PASSWORD="Login%12345"

echo "Setting password..."
echo "${USERNAME}:${PASSWORD}" | chpasswd

echo "Unlocking account if locked..."
passwd -u "${USERNAME}" 2>/dev/null || true

echo "Backing up sshd_config..."
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak.$(date +%F-%H%M%S)

SSHD_CONFIG="/etc/ssh/sshd_config"

# PasswordAuthentication
if grep -q "^#PasswordAuthentication" "$SSHD_CONFIG"; then
    sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication yes/' "$SSHD_CONFIG"
elif grep -q "^PasswordAuthentication" "$SSHD_CONFIG"; then
    sed -i 's/^PasswordAuthentication.*/PasswordAuthentication yes/' "$SSHD_CONFIG"
else
    echo "PasswordAuthentication yes" >> "$SSHD_CONFIG"
fi

# UsePAM
if grep -q "^#UsePAM" "$SSHD_CONFIG"; then
    sed -i 's/^#UsePAM.*/UsePAM yes/' "$SSHD_CONFIG"
elif grep -q "^UsePAM" "$SSHD_CONFIG"; then
    sed -i 's/^UsePAM.*/UsePAM yes/' "$SSHD_CONFIG"
else
    echo "UsePAM yes" >> "$SSHD_CONFIG"
fi

# Optional: Enable keyboard interactive authentication
if grep -q "^#KbdInteractiveAuthentication" "$SSHD_CONFIG"; then
    sed -i 's/^#KbdInteractiveAuthentication.*/KbdInteractiveAuthentication yes/' "$SSHD_CONFIG"
elif grep -q "^KbdInteractiveAuthentication" "$SSHD_CONFIG"; then
    sed -i 's/^KbdInteractiveAuthentication.*/KbdInteractiveAuthentication yes/' "$SSHD_CONFIG"
else
    echo "KbdInteractiveAuthentication yes" >> "$SSHD_CONFIG"
fi

echo "Validating sshd configuration..."
sshd -t

echo "Restarting SSH..."
systemctl restart ssh

echo
echo "========== Verification =========="
sshd -T | grep -E "passwordauthentication|usepam|pubkeyauthentication|permitrootlogin"

echo
echo "User status:"
passwd -S ${USERNAME}

echo
echo "SSH service:"
systemctl --no-pager status ssh

echo
echo "Completed successfully."

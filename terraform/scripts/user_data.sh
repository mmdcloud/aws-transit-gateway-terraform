#!/bin/bash
sudo apt-get update
sudo apt-get install -y nginx

# Ensure Amazon SSM Agent is running for Session Manager
if ! systemctl is-active --quiet snap.amazon-ssm-agent.amazon-ssm-agent.service; then
  sudo snap start amazon-ssm-agent || sudo snap install amazon-ssm-agent --classic
fi

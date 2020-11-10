# Terraform Simple System
Terraform experiment with AWS
  - New VPC with a private and a DMZ sub networks;
  - SSH bastion for ssh access to the resources inside the VPC;
  - Webserver with a static webpage using nginx, serving a test-only purposed https auto-signed certificate;
  - Backend server (a simple ec2 instance, but it can be anything really, like a DB...)

TODO:
  - Make the example more modular;
  - Try some simple webserver  + postgresql deployment;
  - Add another provisioner for configuration

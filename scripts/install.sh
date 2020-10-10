#!/usr/bin/env bash
#
# Install AWS related packaging
#
set -e

mkdir -p ~/.terraform.d/plugins

TERRAFORM_AWS_VERSION=2.68.0

if ! ls ~/.terraform.d/plugins/terraform-provider-aws_v${TERRAFORM_AWS_VERSION}_* 1>/dev/null 2>&1
then
    wget https://releases.hashicorp.com/terraform-provider-aws/${TERRAFORM_AWS_VERSION}/terraform-provider-aws_${TERRAFORM_AWS_VERSION}_linux_amd64.zip 2>/dev/null
    unzip -o terraform-provider-aws_${TERRAFORM_AWS_VERSION}_linux_amd64.zip -d ~/.terraform.d/plugins
fi

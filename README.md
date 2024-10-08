# Kubernetes Technical Briefing IaC Deployment
This repository contains code to automate deployment of infrastructure for a Kubernetes Cluster

## Prerequisites
* [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-windows?tabs=azure-cli)
* [Bicep Tools](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install)

## Setup
* Open [deploy.sh](https://github.com/ckellywilson/ktb-aks-infra/blob/main/infra/deploy.sh).
* Change `location` variable to "centralus".
* Change `nodeSize` outside of [restricted VM Size](https://learn.microsoft.com/en-us/azure/aks/quotas-skus-regions#restricted-vm-sizes).

## Execute
* Execute [deploy.sh](https://github.com/ckellywilson/ktb-aks-infra/blob/main/infra/deploy.sh).
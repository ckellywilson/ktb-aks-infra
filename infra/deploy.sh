#!/bin/bash

# Login to Azure
echo "Logging in to Azure..."
az login --use-device-code

# Read the default subscription
read -p "Enter the subscription ID: " subscriptionId
echo "subscriptionId: $subscriptionId"

# Set the default subscription
echo "Setting the default subscription..."
az account set --subscription $subscriptionId

# Variables
# Get the Azure AD signed-in user ID
echo "Getting the Azure AD signed-id user ID..."
adminUserId=$(az ad signed-in-user show --query "id" --output tsv)
echo "adminUserId: $adminUserId"

# Get the initials for the resources
read -p 'Enter your initials for the resources: ' initials
echo "initials: $initials"

# Set suffix for the resources
echo "Setting the prefix for the resources..."
prefix="${initials}ktb"

# Generate ED25519 SSH key
echo "Generating ED25519 SSH key..."
ssh-keygen -t rsa -f ~/.ssh/id_rsa -N ""

# Set the tags
echo "Setting the tags..."
tags="{'project':'${prefix}'}"

# Get the public key
keyData=$(cat ~/.ssh/id_rsa.pub)

# Set the location
location="centralus"

# Set the deployment name
deploymentName="${prefix}-deployment"

# Set the resource group name
resourceGroupName="${prefix}-rg"

# Get node size
# query to find available vm skus in the location az vm list-skus --location $location --size Standard_D2 --output table
nodeSize='Standard_D2ds_v5'
# nodeSize='Standard_D2_v2'
# nodeSize='Standard_D4ds_v5'

# Deploy AKS cluster using Bicep template
az deployment sub create --name $deploymentName \
    --location $location \
    --parameters ./bicep/main.bicepparam \
    --parameters location="$location" \
    --parameters resourceGroupName="$resourceGroupName" \
    --parameters keyData="$keyData" \
    --parameters prefix="$prefix" \
    --parameters nodeSize="$nodeSize" \
    --parameters adminUserId="$adminUserId" \
    --parameters tags="$tags" \
    --template-file ./bicep/main.bicep

# Get the AKS cluster credentials from deployment outputs
echo "Getting the AKS cluster credentials..."
az aks get-credentials \
 --resource-group $(az deployment sub show -n $deploymentName --query "properties.outputs.resourceGroupName.value" --output tsv) \
 --name $(az deployment sub show -n $deploymentName --query "properties.outputs.aksName.value" --output tsv)

# add helm repo for scubakiz https://scubakiz.github.io/clusterinfo/
echo "Adding helm repo for scubakiz..."
helm repo add scubakiz https://scubakiz.github.io/clusterinfo/
helm repo update
helm install clusterinfo scubakiz/clusterinfo

# install helm nginx ingress controller
echo "Installing helm nginx ingress controller..."
helm upgrade --install ingress-nginx ingress-nginx \
--repo https://kubernetes.github.io/ingress-nginx \
--namespace ingress-nginx --create-namespace \
--set controller.nodeSelector."kubernetes\.io/os"=linux \
--set defaultBackend.nodeSelector."kubernetes\.io/os"=linux \
--set controller.service.externalTrafficPolicy=Local \
--set defaultBackend.image.image=defaultbackend-amd64:1.5

# enable AKS secrets store CSI driver
echo "Enabling AKS secrets store CSI driver..."
az aks enable-addons \
 --addons azure-keyvault-secrets-provider \
 --resource-group $(az deployment sub show -n $deploymentName --query "properties.outputs.resourceGroupName.value" --output tsv) \
 --name $(az deployment sub show -n $deploymentName --query "properties.outputs.aksName.value" --output tsv)




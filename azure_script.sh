#!/bin/bash


echo "Welcome to Azure Adventure"
read -p "Enter Resource Gourp Name: " rgname

az group create \
--name ${rgname} \
--location eastus


read -p "Enter Vnet Name: " Vname

az network vnet create \
--address-prefixes 13.0.0.0/16 \
--name ${Vname} \
--resource-group ${rgname} \
--subnet-name subnet1

az network vnet subnet create \
--resource-group ${rgname} \
--vnet-name ${Vname} \
--name subnet2 \
--address-prefix 13.0.1.0/24

az network nsg create --resource-group ${rgname} --name ShaharBackendNSG

az network nsg rule create \
--resource-group ${rgname} \
--nsg-name ShaharBackendNSG \
--name http \
--access allow \
--protocol Tcp \
--direction Inbound \
--priority 200 \
--source-address-prefix 212.179.161.98/32 34.99.159.243/32 \
--source-port-range "*" \
--destination-address-prefix "*" \
--destination-port-range 80


az network nsg rule create \
--resource-group ${rgname} \
--nsg-name ShaharBackendNSG \
--name ssh \
--access allow \
--protocol Tcp \
--direction Inbound \
--priority 210 \
--source-address-prefix 212.179.161.98/32 34.99.159.243/32 \
--source-port-range "*" \
--destination-address-prefix "*" \
--destination-port-range 22 


az network lb create \
--resource-group ${rgname} \
--name MyLB \
--public-ip-address MyPublicIP \
--frontend-ip-name MyFrontEndPool \
--backend-pool-name MyBackEndPool \
--sku Standard

az network lb probe create \
--resource-group ${rgname} \
--lb-name MyLB \
--name MyHealthProb \
--protocol tcp \
--port 80

az network lb rule create \
--resource-group ${rgname} \
--lb-name MyLB \
--name MyHttpRule \
--protocol tcp \
--frontend-port 80 \
--backend-port 80 \
--frontend-ip-name MyFrontEndPool \
--backend-pool-name MyBackEndPool \
--probe-name MyHealthProb \
--idle-timeout 30

az vm availability-set create --name AV \
--resource-group ${rgname} \
--location eastus

echo "Createing VM1 - Name...?"
read -p "Enter VM Name: " vm1name

az vm create --resource-group ${rgname} \
--name ${vm1name} \
--image UbuntuLTS \
--ssh-key-values ~/.ssh/id_rsa.pub \
--public-ip-address "" \
--location eastus \
--zone 1 \
--no-wait \
--nsg ShaharBackendNSG

echo "Createing VM2 - Name...?"
read -p "Enter VM Name: " vm2name

az vm create --resource-group ${rgname} \
--name ${vm2name} \
--image UbuntuLTS \
--ssh-key-values ~/.ssh/id_rsa.pub \
--public-ip-address "" \
--location eastus \
--zone 1 \
--no-wait \
--nsg ShaharBackendNSG

az network nic ip-config address-pool add \
--address-pool MyBackEndPool \
--ip-config-name "ipconfig${vm1name}" \
--nic-name "${vm1name}VMNic" \
--resource-group ${rgname} \
--lb-name MyLB

az network nic ip-config address-pool add \
--address-pool MyBackEndPool \
--ip-config-name "ipconfig${vm2name}" \
--nic-name "${vm2name}VMNic" \
--resource-group ${rgname} \
--lb-name MyLB

# create KeyVaukt Under ${rgname} resource group

az keyvault create \
--resource-group ${rgname} \
--name "${rgname}MyKeyVault" \
--location eastus \
--sku Standard

az keyvault secret set --name PRK --vault-name "${rgname}MyKeyVault" --file ~/.ssh/id_rsa
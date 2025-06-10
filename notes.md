
## Configure remote Terraform state in Azure

```bash
# 1. resource group
az group create --name rg-elkhorn-wus2 --location wus2

# 2. create storage account
az storage account create --resource-group rg-elkhorn-wus2 --name stoelkhornu3g3pw --sku Standard_LRS --encryption-services blob

# 3. blob container for global state file
az storage container create --name tfstate-global --account-name stoelkhornu3g3pw
```

Configure terraform backend:
```json
terraform {
    required_version = ">= 1.5.0"
    backend "azurerm" {
        resource_group_name = "rg-elkhorn-wus2"
        storage_account_name = "tfstate71d6f"
        container_name = "tfstate-global" /* change for different environments */
        key = "terraform.tfstate"
    }
}
```

## Useful commands:

```bash
terraform init

# upgrade any terraform providers that have pinned versions
terraform init -upgrade

# create a plan to update the current state to resemble the desired state
terraform plan

# create a plan to deprovision/destroy all resources managed by terraform
terraform plan -destroy

# detry resources
terraform destroy -auto-approve

terraform state list
terraform state show 

terraform apply -auto-approve
terraform apply -refresh-only
terraform apply -replace azurerm_linux_virtual_machine.vm-tftest

terraform output

terraform console -var-file="xyz.tfvars" 
terraform fmt
```

## Azure Networking

Given the network address range 10.0.0.0/24, Azure will reserve some addresses:

- 10.0.0.0 Network Id
- 10.0.0.1 Reserved by Azure for Default Gateway. Clients use this to communicate with computers outside of the subnet.
- 10.0.0.2, 10.0.0.3 Reserved by Azure to map Azure DNS IP addresses to the virtual network space
- 10.0.0.255 Network broadcast address. Used to communicate with all computers attached to the subnnet.
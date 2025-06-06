
#!/bin/bash

# Defina o nome do grupo de recursos
resourceGroupName="guilherme.sreis_labs"

# Obtenha a lista de nomes de discos no grupo de recursos
disks=$(az disk list --resource-group $resourceGroupName --query "[].name" --output tsv)

# Loop para excluir cada disco
for disk in $disks
do
    az disk delete --name $disk --resource-group $resourceGroupName --yes --no-wait
done
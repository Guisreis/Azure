#!/bin/bash

#Variáveis
resource_group_name="guilherme.sreis_labs"
vm_name="VM-WIN"
vm_antiga="VM-WIN2"
snapshot_base_name_SO="VM_WIN_snapshot_SO"
snapshot_base_name_Disk1="VM_WIN_snapshot-Disk1"
snapshot_base_name_Disk2="VM_WIN_snapshot-Disk2"
new_disk_name_base_SO="disk-VM-WIN-SO"
new_disk_name_base_disk1="disk-VM-WIN-DISK1"
new_disk_name_base_disk2="disk-VM-WIN-DISK2"
new_vm_name="VM-WIN2"
source_disk_id_SO="/subscriptions/f499b40d-558a-45e7-bfac-b43ca2015e1c/resourceGroups/guilherme.sreis_labs/providers/Microsoft.Compute/disks/VM-WIN_disk1_565e2964882c4b3681481d4dba08486e"
source_disk_id_disk1="/subscriptions/f499b40d-558a-45e7-bfac-b43ca2015e1c/resourceGroups/guilherme.sreis_labs/providers/Microsoft.Compute/disks/disk-1"
source_disk_id_disk2="/subscriptions/f499b40d-558a-45e7-bfac-b43ca2015e1c/resourceGroups/guilherme.sreis_labs/providers/Microsoft.Compute/disks/disk-2"
existing_nic_id="/subscriptions/f499b40d-558a-45e7-bfac-b43ca2015e1c/resourceGroups/guilherme.sreis_labs/providers/Microsoft.Network/networkInterfaces/VM-WIN2VMNic"

#Deletar instância de homolog antiga (VM e discos)
echo "Iniciando a exclusão da instância de homolog antiga..."
az vm delete --resource-group $resource_group_name --name $vm_antiga --yes --no-wait

#Aguardar até que a VM antiga seja desalocada e excluída
while az vm show --resource-group $resource_group_name --name $vm_antiga &>/dev/null; do
    echo "Aguardando a desalocação e exclusão da VM antiga..."
    sleep 10
done

#Criar snapshot do disco SO
snapshot_name_1="$snapshot_base_name_SO-$(date +%Y%m%d%H%M%S)"
az snapshot create --resource-group $resource_group_name --name $snapshot_name_1 --source $source_disk_id_SO --sku "Premium_LRS" --hyper-v-generation "V2"

echo "Snapshot criado disk SO com sucesso."

# Criar snapshot do disco - 01
snapshot_name_2="$snapshot_base_name_Disk1-$(date +%Y%m%d%H%M%S)"
az snapshot create --resource-group $resource_group_name --name $snapshot_name_2 --source $source_disk_id_disk1 --sku "Standard_LRS" --hyper-v-generation "V2"

echo "Snapshot criado disk1 com sucesso."

# Criar snapshot do disco - 02
snapshot_name_3="$snapshot_base_name_Disk2-$(date +%Y%m%d%H%M%S)"
az snapshot create --resource-group $resource_group_name --name $snapshot_name_3 --source $source_disk_id_disk2 --sku "Standard_LRS" --hyper-v-generation "V2"

echo "Snapshot disk2 criado com sucesso."

# Obter o ID do snapshot_SO
snapshot_id_SO=$(az snapshot show --resource-group $resource_group_name --name $snapshot_name_1 --query 'id' --output tsv)

echo "ID do Snapshot_SO encontrado."

# Obter o ID do snapshot_Disk1
snapshot_id_Disk1=$(az snapshot show --resource-group $resource_group_name --name $snapshot_name_2 --query 'id' --output tsv)

echo "ID do Snapshot_Disk1 encontrado."

# Obter o ID do snapshot_Disk2
snapshot_id_disk2=$(az snapshot show --resource-group $resource_group_name --name $snapshot_name_3 --query 'id' --output tsv)

echo "ID do Snapshot_Disk2 encontrado."

# Criar um novo disco a partir do snapshot
new_disk_name_SO="$new_disk_name_base_SO-$(date +%Y%m%d%H%M%S)"
az disk create --resource-group $resource_group_name --name $new_disk_name_SO --source $snapshot_id_SO --sku "Premium_LRS" --hyper-v-generation "V2"

echo "Disco_SO criado com sucesso."

# Criar um novo disco a partir do snapshot
new_disk_name_disk1="$new_disk_name_base_disk1-$(date +%Y%m%d%H%M%S)"
az disk create --resource-group $resource_group_name --name $new_disk_name_disk1 --source $snapshot_id_Disk1 --sku "Standard_LRS" --hyper-v-generation "V2"

echo "Disco_Disk1 criado com sucesso."

# Criar um novo disco a partir do snapshot
new_disk_name_disk2="$new_disk_name_base_disk2-$(date +%Y%m%d%H%M%S)"
az disk create --resource-group $resource_group_name --name $new_disk_name_disk2 --source $snapshot_id_disk2 --sku "Standard_LRS" --hyper-v-generation "V2"

echo "Disco_Disk2 criado com sucesso."

# Obter o ID do novo disco
new_disk_id_SO=$(az disk show --resource-group $resource_group_name --name $new_disk_name_SO --query 'id' --output tsv)

echo "ID do Disco_SO encontrado."

# Obter o ID do novo disco
new_disk_id_disk1=$(az disk show --resource-group $resource_group_name --name $new_disk_name_disk1 --query 'id' --output tsv)

echo "ID do Disco_disk1 encontrado."

# Obter o ID do novo disco
new_disk_id_disk2=$(az disk show --resource-group $resource_group_name --name $new_disk_name_disk2 --query 'id' --output tsv)

echo "ID do Disco_disk2 encontrado."

# Criar nova VM usando o novo disco, a interface de rede e o IP público existentes
az vm create --resource-group $resource_group_name --name $new_vm_name --attach-os-disk $new_disk_id_SO  --attach-data-disks $new_disk_id_disk1 $new_disk_id_disk2 --os-type "Windows" --nics $existing_nic_id --size "Standard_DS2_v2"  --security-type "TrustedLaunch"

echo "Nova VM com o disco do sistema operacional e 2 discos de armazenamento criada com sucesso."




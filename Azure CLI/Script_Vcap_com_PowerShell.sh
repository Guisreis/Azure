#!/bin/bash

#RESOURCE GROUP QUE ESTÃO OS RECURSOS"
resource_group_name="mercosul-network"
#VM DE ORIGEM
vm_name="teste-bootstrap" 
#Localização dos recursos
location="brazilsouth"
#VM ANTIGA A SER DELETADA
vm_antiga="teste-bootstrap2" 
#SNAPSHOT DO SO
snapshot_base_name_SO="replicacao-teste_snapshot_SO_VC3" 
#SNAPSHOT DO DISCO 1
snapshot_base_name_Disk1="replicacao-teste_snapshot-Disk1_VC3" 
#NOME DO NOVO DISCO SO A SER GERADO
new_disk_name_base_SO="disk-replicacao-teste-SO_VC3" 
#NOME DO NOVO DISCO 1 A SER GERADO
new_disk_name_base_disk1="disk-replicacao-teste-DISK1_VC3"  
#NOME DA NOVA VM
new_vm_name="teste-bootstrap2" 
#ID DO DISCO DE SO DE ORIGEM
source_disk_id_SO="/subscriptions/ed13423a-8cbe-4f5b-931f-f4026d2b1971/resourceGroups/mercosul-network/providers/Microsoft.Compute/disks/teste-bootstrap_OsDisk_1_22affd98b670437fa285d742ff2947bf"
#ID DO DISCO 1 DE ORIGEM
source_disk_id_disk="/subscriptions/ed13423a-8cbe-4f5b-931f-f4026d2b1971/resourceGroups/mercosul-network/providers/Microsoft.Compute/disks/teste-bootstrap_DataDisk_0"
#ID DA INTERFACE DE REDE EXISTENTE
existing_nic_id="/subscriptions/ed13423a-8cbe-4f5b-931f-f4026d2b1971/resourceGroups/mercosul-network/providers/Microsoft.Network/networkInterfaces/teste-bootstrap2174_z1"



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
az snapshot create --resource-group $resource_group_name --name $snapshot_name_1 --source $source_disk_id_SO --sku "Premium_LRS" --hyper-v-generation "V2" --location $location

echo "Snapshot criado disk SO com sucesso."

# Criar snapshot do disco - 01
snapshot_name_2="$snapshot_base_name_Disk1-$(date +%Y%m%d%H%M%S)"
az snapshot create --resource-group $resource_group_name --name $snapshot_name_2 --source $source_disk_id_disk --sku "Premium_LRS" --hyper-v-generation "V2"  --location $location


echo "Snapshot criado disk1 com sucesso."


# Obter o ID do snapshot_SO
snapshot_id_SO=$(az snapshot show --resource-group $resource_group_name --name $snapshot_name_1 --query 'id' --output tsv) 

echo "ID do Snapshot_SO encontrado."

# Obter o ID do snapshot_Disk1
snapshot_id_Disk1=$(az snapshot show --resource-group $resource_group_name --name $snapshot_name_2 --query 'id' --output tsv)

echo "ID do Snapshot_Disk1 encontrado."


# Criar um novo disco a partir do snapshot
new_disk_name_SO="$new_disk_name_base_SO-$(date +%Y%m%d%H%M%S)"
az disk create --resource-group $resource_group_name --name $new_disk_name_SO --source $snapshot_id_SO --sku "Premium_LRS" --hyper-v-generation "V2" --location $location

echo "Disco_SO criado com sucesso."

# Criar um novo disco a partir do snapshot
new_disk_name_disk1="$new_disk_name_base_disk1-$(date +%Y%m%d%H%M%S)"
az disk create --resource-group $resource_group_name --name $new_disk_name_disk1 --source $snapshot_id_Disk1 --sku "Premium_LRS" --hyper-v-generation "V2" --location $location

echo "Disco_Disk1 criado com sucesso."


# Obter o ID do novo disco
new_disk_id_SO=$(az disk show --resource-group $resource_group_name --name $new_disk_name_SO --query 'id' --output tsv)

echo "ID do Disco_SO encontrado."

# Obter o ID do novo disco
new_disk_id_disk1=$(az disk show --resource-group $resource_group_name --name $new_disk_name_disk1 --query 'id' --output tsv)

echo "ID do Disco_disk1 encontrado."

# Criar nova VM usando o novo disco, a interface de rede e o IP público existentes
az vm create --resource-group $resource_group_name --name $new_vm_name --attach-os-disk $new_disk_id_SO  --attach-data-disks $new_disk_id_disk1 --os-type "Windows" --nics $existing_nic_id --size "Standard_DS2_v2"  --security-type "TrustedLaunch" --location $location 

echo "Nova VM com o disco do sistema operacional e 1 disco de armazenamento criada com sucesso."

# Aguardar a máquina virtual Windows iniciar completamente
echo "Aguardando a máquina virtual iniciar..."
sleep 60  # Espera por 60 segundos

az vm run-command invoke --command-id RunPowerShellScript --name $new_vm_name --resource-group $resource_group_name --script "
# Seu script PowerShell aqui
Rename-Computer -NewName 'teste-bootstrap2' -Force -Restart
"
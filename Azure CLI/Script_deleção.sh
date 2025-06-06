#!/bin/bash

# Variáveis
resourceGroup="guilherme.sreis_labs"
homologVMName="teste-2"
nome_imagem="Image-test"
tipo_sistema="Linux"
disco_origem="/subscriptions/f499b40d-558a-45e7-bfac-b43ca2015e1c/resourceGroups/GUILHERME.SREIS_LABS/providers/Microsoft.Compute/disks/VM-TEST_OsDisk_1_5109f6aa33274a248920bb6e6cd47532"
geracao_hyper_v="V2"
nome_vm="VM-TEST2"
tamanho_vm="Standard_B1ls"  
nome_nic="Inter_vm2"  


# Passo 1: Deletar instância de homolog antiga (VM e discos)
echo "Iniciando a exclusão da instância de homolog antiga..."
az vm delete --resource-group $resourceGroup --name $homologVMName --yes --no-wait

# Aguardar até que a VM antiga seja excluída
while [ "$(az vm show --resource-group $resourceGroup --name $homologVMName 2>/dev/null)" != "" ]; do
    echo "Aguardando a exclusão da VM antiga..."
    sleep 10
done

echo "A VM antiga foi excluída."

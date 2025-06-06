#!/bin/bash

# Variáveis
resourceGroup="guilherme.sreis_labs"
homologVMName="VM-TEST2"
tipo_sistema="Linux"
disco_origem="/subscriptions/f499b40d-558a-45e7-bfac-b43ca2015e1c/resourceGroups/GUILHERME.SREIS_LABS/providers/Microsoft.Compute/disks/VM-TEST_OsDisk_1_5109f6aa33274a248920bb6e6cd47532"
geracao_hyper_v="V2"
tamanho_vm="Standard_B1ls"
nome_nic="Inter_vm2"
nome_vm_existente="VM-TEST"  # Adicione o nome da VM existente
nome_vm="VM-TEST2"

# Passo 1: D"eletar instância de homolog antiga (VM e discos)
echo "Iniciando a exclusão da instância de homolog antiga..."
az vm delete --resource-group $resourceGroup --name $homologVMName --yes --no-wait

# Aguardar até que a VM antiga seja excluída
while [ "$(az vm show --resource-group $resourceGroup --name $homologVMName 2>/dev/null)" != "" ]; do
    echo "Aguardando a exclusão da VM antiga..."
    sleep 10
done

echo "A VM antiga foi excluída."

# Recuperar a contagem das imagens existentes com o prefixo "Image-test-v"
contagem_imagens=$(az image list --resource-group "$resourceGroup" --query "[?starts_with(name, 'Image-test-v')]" --output tsv | wc -l)
proximo_numero=$((contagem_imagens + 1))

# Nome da próxima imagem
nome_imagem="Image-test-v$proximo_numero"

# Criar a imagem
az image create -g "$resourceGroup" -n "$nome_imagem" --os-type "$tipo_sistema" --source "$disco_origem" --hyper-v-generation "$geracao_hyper_v"

echo "Imagem $nome_imagem gerada com sucesso"

# Chave pública SSH que você deseja usar para autenticação na VM
sshPublicKey="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC4Wo4vPMUXe3vbh9AAbhA+gcrEax2I2Aflnqx7aex3sJzF9P8PdVt/i3xNOi3hgVOJM4mc/2e9QoTwtxhK8CsQtMqIihkMRBkU6Di+W45eL1l3HL8Y7RCQx//nchecfWTP/U8srwv0G2sRI1O3rhxRmgRCgtKqQja/OQzUKczKPiWNqLqgnHgiu5DRYBcKKZN6bSOqFzTsf5R/0hZ4StOKMPlJXuO3EVQ51Obq034mRCXLY+SLhKr9sJn+7UY4pcEwgZxcdyYCYRYpkymjrZFKGWa67e4bGoA6ubueoGLeIBn8zyoAsL61m6C+NuPRZ820aKsqFpmoEG2suuRivE9VtqdYY5LJp0B1YJiMK4bzeZ0LU5G/eTcuWTE4Z8LITqoyfSjU+6fXxGUCUwECPKBDyLAh0pn8sb/zweFPavwDwe/V5hSMT6m6t6eaTfBKAb7MiNJaUO0jzETbt15J6ZAQsGdhijqOEyctCkmY2XpCKu+FwHi2jBxP8jAvI6Y0wTE= generated-by-azure"

# Criar a VM usando a NIC existente e a chave pública SSH fixa
az vm create -g "$resourceGroup" -n "$nome_vm" --image "$nome_imagem" --size "$tamanho_vm" --admin-username "username" --nics "$nome_nic" --ssh-key-value "$sshPublicKey"

echo "Nova VM $nome_vm criada"


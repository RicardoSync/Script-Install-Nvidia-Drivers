#!/bin/bash

# Verificar si se ejecuta como superusuario
if [ "$EUID" -ne 0 ]; then
  echo "Por favor, ejecuta este script como root o con sudo."
  exit 1
fi

apt install mysql-server apache2 php php-mysql -y
apt install python3-tk python3-pip -y
apt install vlc cava -y

sudo apt-get install wget gpg
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" |sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
rm -f packages.microsoft.gpg
sudo apt install apt-transport-https
sudo apt update
sudo apt install code # or code-insiders

sudo apt install flatpak -y

flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

flatpak install flathub org.kde.kdenlive -y
flatpak install flathub io.github.shiftey.Desktop -y
flatpak install flathub com.obsproject.Studio -y



sudo snap install mysql-workbench-community


# Agregar el repositorio de controladores NVIDIA
echo "Agregando el repositorio de controladores NVIDIA..."
add-apt-repository -y ppa:graphics-drivers/ppa

# Actualizar la lista de paquetes
echo "Actualizando la lista de paquetes..."
apt update

# Actualizar todos los paquetes existentes
echo "Actualizando el sistema..."
apt upgrade -y

# Determinar el controlador recomendado
echo "Buscando el controlador NVIDIA recomendado..."
RECOMMENDED_DRIVER=$(ubuntu-drivers devices | grep recommended | awk '{print $3}')

if [ -z "$RECOMMENDED_DRIVER" ]; then
  echo "No se encontró un controlador recomendado. Revisa manualmente."
  exit 1
fi

echo "Controlador recomendado: $RECOMMENDED_DRIVER"

# Instalar el controlador recomendado
echo "Instalando el controlador NVIDIA: $RECOMMENDED_DRIVER..."
apt install -y $RECOMMENDED_DRIVER

# Crear archivo de configuración para deshabilitar nouveau
echo "Deshabilitando el controlador 'nouveau'..."
cat <<EOF > /etc/modprobe.d/blacklist-nouveau.conf
blacklist nouveau
options nouveau modeset=0
EOF

# Actualizar initramfs
echo "Actualizando la configuración del kernel..."
update-initramfs -u

# Configurar NVIDIA como tarjeta gráfica predeterminada
echo "Configurando NVIDIA como tarjeta gráfica predeterminada..."
prime-select nvidia




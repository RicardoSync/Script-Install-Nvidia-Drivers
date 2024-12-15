#!/bin/bash

# Verificar si se ejecuta como superusuario
if [ "$EUID" -ne 0 ]; then
  echo "Por favor, ejecuta este script como root o con sudo."
  exit 1
fi

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

# Mensaje final
echo "¡Instalación completada! Reinicia el sistema para aplicar los cambios."
echo "Reiniciando en 10 segundos..."
sleep 10
reboot

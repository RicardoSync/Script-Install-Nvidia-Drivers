#!/bin/bash

# Mostrar banner
clear
echo "=========================================="
echo "               CISO Script                "
echo "=========================================="
sleep 2

# Verificar si se ejecuta como superusuario
if [ "$EUID" -ne 0 ]; then
  echo "Por favor, ejecuta este script como root o con sudo."
  exit 1
fi

# Preguntar si se desean instalar los paquetes adicionales
read -p "¿Deseas instalar los paquetes adicionales (Flatpaks, Code, Apache, librerías Python, etc)? (y/n): " install_packages
if [[ "$install_packages" == "y" || "$install_packages" == "Y" ]]; then
  install_extra_packages=true
else
  install_extra_packages=false
fi

# Habilitar repositorios oficiales de Fedora y RPM Fusion
dnf update -y
dnf upgrade -y
echo "Habilitando repositorios oficiales y RPM Fusion..."
dnf install -y dnf-plugins-core
dnf config-manager --set-enabled rpmfusion-free rpmfusion-nonfree

# Agregar repositorio oficial de NVIDIA
echo "Agregando el repositorio oficial de NVIDIA..."
dnf config-manager --add-repo=https://developer.download.nvidia.com/compute/cuda/repos/fedora41/x86_64/cuda-fedora41.repo

# Actualizar la lista de paquetes
echo "Actualizando el sistema..."
dnf upgrade --refresh -y

# Instalar los drivers NVIDIA desde el repositorio oficial
echo "Instalando el controlador NVIDIA desde el repositorio oficial..."
dnf install -y akmod-nvidia xorg-x11-drv-nvidia xorg-x11-drv-nvidia-cuda

# Verificar si nouveau está activo y desactivarlo
echo "Deshabilitando 'nouveau' si está activo..."
if lsmod | grep -q nouveau; then
  echo "Creando archivo de configuración para deshabilitar nouveau..."
  cat <<EOF > /etc/modprobe.d/blacklist-nouveau.conf
blacklist nouveau
options nouveau modeset=0
EOF
  dracut --force
fi

# Configurar NVIDIA para funcionar en Wayland
echo "Configurando NVIDIA para Wayland..."
cat <<EOF > /etc/udev/rules.d/61-gdm-nvidia.rules
# Permitir GDM usar NVIDIA en Wayland
ACTION=="add", SUBSYSTEM=="drm", ENV{DEVNAME}=="/dev/dri/card1", RUN+="/bin/sh -c 'echo nvidia > /sys/class/drm/card1/device/driver_override'"
EOF

# Habilitar NVIDIA como tarjeta gráfica predeterminada
echo "Configurando NVIDIA como tarjeta gráfica predeterminada..."
echo "options nvidia-drm modeset=1" > /etc/modprobe.d/nvidia-drm.conf
dracut --force

# Instalar otros paquetes si el usuario lo eligió
if [ "$install_extra_packages" = true ]; then
  echo "Instalando paquetes adicionales..."

  # Instalar repositorios y aplicaciones de desarrollo
  echo "Instalando repositorios de RPM Fusion..."
  sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
  sudo dnf update @core
  sudo dnf swap ffmpeg-free ffmpeg --allowerasing
  sudo dnf update @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin
  sudo dnf swap mesa-va-drivers mesa-va-drivers-freeworld
  sudo dnf swap mesa-vdpau-drivers mesa-vdpau-drivers-freeworld
  sudo dnf install libva-nvidia-driver

  # Instalar otros paquetes para NVIDIA y dependencias
  sudo dnf install kernel-devel kernel-headers gcc make dkms acpid libglvnd-glx libglvnd-opengl libglvnd-devel pkgconfig
  sudo dnf makecache
  sudo dnf install akmod-nvidia xorg-x11-drv-nvidia-cuda
  sudo dnf install libva-nvidia-driver

  # Instalar Visual Studio Code
  echo "Instalando Visual Studio Code..."
  sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
  echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null
  dnf check-update
  dnf install -y python3-pip python3-tkinter vlc cava simplescreenrecorder wireguard
  dnf install -y system-config-printer
  sudo dnf -y install code # or code-insiders

  # Instalar Flatpaks
  echo "Instalando Flatpaks..."
  flatpak install flathub org.kde.kdenlive -y
  flatpak install flathub com.jetbrains.PyCharm-Community -y
  flatpak install flathub com.spotify.Client -y
  flatpak install flathub io.github.shiftey.Desktop -y
  flatpak install flathub com.obsproject.Studio -y
  flatpak install flathub com.brave.Browser -y

  # Instalar Apache
  echo "Instalando Apache..."
  dnf install -y httpd

  # Habilitar y arrancar el servicio de Apache
  echo "Habilitando y arrancando Apache..."
  systemctl enable httpd
  systemctl start httpd

  # Abrir el puerto 80 en el firewall
  echo "Abriendo el puerto 80 en el firewall..."
  firewall-cmd --permanent --add-service=http
  firewall-cmd --reload
fi

# Mensaje final
echo "Reiniciando en 30 segundos..."
sleep 3
clear
echo "Cuando se reinicie, ejecuta el segundo script final-nvidia.sh"
sleep 30
reboot

#!/bin/bash

# Mostrar banner
clear
echo "=========================================="
echo "               CISO Script                "
echo "=========================================="
sleep 2

# Verificar si se ejecuta como superusuario
if [ "$EUID" -ne 0 ]; then
  echo "Por favor, ejecuta este script como root o con "
  exit 1
fi

# Actualizar el sistema
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

# Instalar paquetes adicionales sin preguntar
echo "Instalando paquetes adicionales..."

# Instalar repositorios y aplicaciones de desarrollo
echo "Instalando repositorios de RPM Fusion..."
dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
dnf update -y @core
dnf swap -y ffmpeg-free ffmpeg --allowerasing
dnf update -y @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin
dnf swap -y mesa-va-drivers mesa-va-drivers-freeworld
dnf swap -y mesa-vdpau-drivers mesa-vdpau-drivers-freeworld
dnf install -y libva-nvidia-driver

# Instalar otros paquetes para NVIDIA y dependencias
dnf install -y kernel-devel kernel-headers gcc make dkms acpid libglvnd-glx libglvnd-opengl libglvnd-devel pkgconfig
dnf makecache
dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda
dnf install -y libva-nvidia-driver

# Instalar Visual Studio Code
echo "Instalando Visual Studio Code..."
rpm --import https://packages.microsoft.com/keys/microsoft.asc
echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | tee /etc/yum.repos.d/vscode.repo > /dev/null
dnf check-update
dnf install -y python3-pip python3-tkinter vlc java-11-openjdk wireguard-tools
dnf install -y system-config-printer
dnf install -y code # o code-insiders
dnf install -y nvidia-prime
dnf install -y gnome-tweaks

# Configuración de Zsh con Oh My Zsh y Powerlevel10k
echo "Instalando y configurando Zsh, Oh My Zsh y Powerlevel10k..."

# Cambiar la shell por defecto a Zsh
chsh -s /bin/zsh

# Instalar Zsh y los plugins necesarios
dnf install -y zsh zsh-autosuggestions zsh-syntax-highlighting

# Instalar Oh My Zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || {
    echo "No se pudo instalar Oh My Zsh."
    exit 1
}

# Instalar Powerlevel10k (a través de los repositorios de GitHub)
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k || {
    echo "No se pudo clonar Powerlevel10k."
    exit 1
}

# Configurar Zsh para usar Powerlevel10k y los plugins de autosuggestions y syntax-highlighting
echo 'ZSH_THEME="powerlevel10k/powerlevel10k"' >> ~/.zshrc
echo 'source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh' >> ~/.zshrc
echo 'source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh' >> ~/.zshrc

# Recargar la configuración de Zsh
source ~/.zshrc

# Configuración de Java (si tienes varias versiones)
echo "Configurando la versión de Java..."
alternatives --config java

# Instalar Flatpaks (si es necesario)
echo "Instalando Flatpaks..."
#flatpak install -y flathub org.kde.kdenlive
#flatpak install -y flathub io.github.shiftey.Desktop
#flatpak install -y flathub com.obsproject.Studio

#instalacion de chrome y paquetes rpm
wget https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm
dnf -y install google-chrome-stable_current_x86_64.rpm

wget https://dbeaver.io/files/dbeaver-ce-latest-stable.x86_64.rpm
dnf -y install dbeaver-ce-latest-stable.x86_64.rpm

wget https://dev.mysql.com/get/mysql80-community-release-fc41-1.noarch.rpm
dnf -y install mysql80-community-release-fc41-1.noarch.rpm

dnf -y install mysql-community-server

# habilitar mysql
systemctl start mysqld
systemctl enable mysqld


wget https://dev.mysql.com/get/Downloads/MySQLGUITools/mysql-workbench-community-8.0.29-1.fc41.x86_64.rpm
dnf -y install mysql-workbench-community-8.0.29-1.fc41.x86_64.rpm


# Mensaje final
echo "Reiniciando en 30 segundos..."
sleep 3
clear
echo "Cuando se reinicie, ejecuta el segundo script final-nvidia.sh"
sleep 30
reboot

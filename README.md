# CISO Script

Este script automatiza la configuración de un sistema Fedora 41 para instalar y configurar drivers NVIDIA, herramientas de desarrollo, software de productividad, y servicios como Apache. Es ideal para aquellos que desean optimizar su entorno de trabajo, habilitar NVIDIA en Wayland, y tener un conjunto de herramientas de desarrollo listas con facilidad.

## Características

1. **Actualización del sistema**: 
   - Actualiza los repositorios y paquetes instalados en el sistema.
   - Habilita los repositorios oficiales y RPM Fusion para permitir la instalación de controladores y software adicional.

2. **Instalación de controladores NVIDIA**:
   - Instala el controlador oficial de NVIDIA, incluyendo los paquetes necesarios para la aceleración de hardware.
   - Desactiva el driver `nouveau` (si está activo) para evitar conflictos con los controladores de NVIDIA.
   - Configura el sistema para usar los controladores de NVIDIA en Wayland y establece NVIDIA como la tarjeta gráfica predeterminada.
   
3. **Instalación de herramientas y repositorios de desarrollo**:
   - Instala los paquetes de desarrollo necesarios como `gcc`, `make`, `dkms`, y más.
   - Instala herramientas adicionales de desarrollo, como Visual Studio Code, Python, y otras aplicaciones comunes.

4. **Instalación de Flatpaks**:
   - Instala aplicaciones populares desde Flathub como **Kdenlive**, **PyCharm**, **Spotify**, **Brave Browser**, entre otros.

5. **Instalación y configuración de Apache**:
   - Instala el servidor web Apache.
   - Habilita y arranca el servicio de Apache.
   - Configura el firewall para permitir el tráfico HTTP en el puerto 80.

6. **Reinicio del sistema**: 
   - Al finalizar, el script reinicia el sistema automáticamente para aplicar todas las configuraciones y cambios.

## Requisitos

- Fedora 41 o superior.
- Acceso de superusuario (root o `sudo`).
- Conexión a Internet para descargar los paquetes necesarios.

## Cómo usar el script

1. **Clonar el repositorio**:

   ```bash
   git clone https://github.com/tu-usuario/ciso-script.git
   cd ciso-script


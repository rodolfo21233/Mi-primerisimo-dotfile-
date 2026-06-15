#!/usr/bin/env bash
# install.sh - Script para instalar y enlazar dotfiles

# Directorio donde se encuentran tus dotfiles (se asume que ejecutas el script desde la raíz del repositorio)
DOTFILES_DIR=$(pwd)

echo "Empezando"

# Enlaza la carpeta .config
mkdir -p "$HOME/.config"
ln -sf "$DOTFILES_DIR/.config" "$HOME/.config/dotfiles"


echo "¡Dotfiles instalados exitosamente!"

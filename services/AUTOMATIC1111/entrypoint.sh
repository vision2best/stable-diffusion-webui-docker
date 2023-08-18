#!/bin/bash

set -Eeuo pipefail

# TODO: move all mkdir -p ?
mkdir -p /mnt/auto/sd/config/auto/scripts/
# mount scripts individually
find "${ROOT}/scripts/" -maxdepth 1 -type l -delete
cp -vrfTs /mnt/auto/sd/config/auto/scripts/ "${ROOT}/scripts/"

# Set up config file
python /docker/config.py /mnt/auto/sd/config/auto/config.json

if [ ! -f /mnt/auto/sd/config/auto/ui-config.json ]; then
  echo '{}' >/mnt/auto/sd/config/auto/ui-config.json
fi

if [ ! -f /mnt/auto/sd/config/auto/styles.csv ]; then
  touch /mnt/auto/sd/config/auto/styles.csv
fi

# copy models from original models folder
mkdir -p /mnt/auto/sd/models/VAE-approx/ /mnt/auto/sd/models/karlo/

rsync -a --info=NAME ${ROOT}/models/VAE-approx/ /mnt/auto/sd/models/VAE-approx/
rsync -a --info=NAME ${ROOT}/models/karlo/ /mnt/auto/sd/models/karlo/

declare -A MOUNTS

MOUNTS["/root/.cache"]="/mnt/auto/sd/.cache"
MOUNTS["${ROOT}/models"]="/mnt/auto/sd/models"

MOUNTS["${ROOT}/embeddings"]="/mnt/auto/sd/embeddings"
MOUNTS["${ROOT}/config.json"]="/mnt/auto/sd/config/auto/config.json"
MOUNTS["${ROOT}/ui-config.json"]="/mnt/auto/sd/config/auto/ui-config.json"
MOUNTS["${ROOT}/styles.csv"]="/mnt/auto/sd/config/auto/styles.csv"
MOUNTS["${ROOT}/extensions"]="/mnt/auto/sd/config/auto/extensions"
MOUNTS["${ROOT}/config_states"]="/mnt/auto/sd/config/auto/config_states"

# extra hacks
MOUNTS["${ROOT}/repositories/CodeFormer/weights/facelib"]="/mnt/auto/sd/.cache"

for to_path in "${!MOUNTS[@]}"; do
  set -Eeuo pipefail
  from_path="${MOUNTS[${to_path}]}"
  rm -rf "${to_path}"
  if [ ! -f "$from_path" ]; then
    mkdir -vp "$from_path"
  fi
  mkdir -vp "$(dirname "${to_path}")"
  ln -sT "${from_path}" "${to_path}"
  echo Mounted $(basename "${from_path}")
done

echo "Installing extension dependencies (if any)"

# because we build our container as root:
chown -R root ~/.cache/
chmod 766 ~/.cache/

shopt -s nullglob
# For install.py, please refer to https://github.com/AUTOMATIC1111/stable-diffusion-webui/wiki/Developing-extensions#installpy
list=(./extensions/*/install.py)
for installscript in "${list[@]}"; do
  PYTHONPATH=${ROOT} python "$installscript"
done

if [ -f "/mnt/auto/sd/config/auto/startup.sh" ]; then
  pushd ${ROOT}
  echo "Running startup script"
  . /mnt/auto/sd/config/auto/startup.sh
  popd
fi

exec "$@"

#!/usr/bin/env bash

set -Eeuo pipefail

# TODO: maybe just use the .gitignore file to create all of these
mkdir -vp /mnt/auto/sd/.cache \
  /mnt/auto/sd/embeddings \
  /mnt/auto/sd/config/ \
  /mnt/auto/sd/models/ \
  /mnt/auto/sd/models/Stable-diffusion \
  /mnt/auto/sd/models/GFPGAN \
  /mnt/auto/sd/models/RealESRGAN \
  /mnt/auto/sd/models/LDSR \
  /mnt/auto/sd/models/VAE

echo "Downloading, this might take a while..."

aria2c -x 10 --disable-ipv6 --input-file /docker/links.txt --dir /mnt/auto/sd/models --continue

echo "Checking SHAs..."

parallel --will-cite -a /docker/checksums.sha256 "echo -n {} | sha256sum -c"

cat <<EOF
By using this software, you agree to the following licenses:
https://github.com/AbdBarho/stable-diffusion-webui-docker/blob/master/LICENSE
https://github.com/CompVis/stable-diffusion/blob/main/LICENSE
https://github.com/AUTOMATIC1111/stable-diffusion-webui/blob/master/LICENSE.txt
https://github.com/invoke-ai/InvokeAI/blob/main/LICENSE
And licenses of all UIs, third party libraries, and extensions.
EOF

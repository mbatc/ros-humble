#!/usr/bin/env bash

set -xeuo pipefail
export PYTHONUNBUFFERED=1
export FEEDSTOCK_ROOT=`pwd`
export EMSDK_VER="3.1.45"
export MAMBA_ROOT_PREFIX=/home/runner/micromamba
export EMFORGE_DIR=/home/runner/emforge-recipes

"${SHELL}" <(curl -L micro.mamba.pm/install.sh)
eval "$(micromamba shell hook --shell bash)"

micromamba config set remote_max_retries 5

micromamba create -n devenv --quiet --yes conda-forge-ci-setup=3 conda-build=3.27 pip boa "quetz-client<= 0.0.4" anaconda-client mamba playwright ruamel.yaml=0.18.1 -c conda-forge -c microsoft
micromamba activate devenv

set -e

export "CONDA_BLD_PATH=$CONDA_PREFIX/conda-bld/"
mkdir -p ${CONDA_BLD_PATH}
mkdir -p ${CONDA_BLD_PATH}/emscripten-wasm32
mkdir -p ${CONDA_BLD_PATH}/linux-64
mkdir -p ${CONDA_BLD_PATH}/noarch
micromamba config append channels conda-forge --env
micromamba config append channels robostack-staging --env
micromamba config append channels https://beta.mamba.pm/channels/robostack-wasm --env
micromamba config append channels https://repo.mamba.pm/emscripten-forge --env
micromamba config append channels $CONDA_BLD_PATH --env

echo "Setup emscripten-forge recipes"
mkdir -p $EMFORGE_DIR
pushd $EMFORGE_DIR
git clone https://github.com/mbatc/emscripten-forge-recipes.git .
./emsdk/setup_emsdk.sh $EMSDK_VER $(pwd)/emsdk_install
python -m pip install git+https://github.com/DerThorsten/boa.git@python_api_v2 --no-deps --ignore-installed
popd

for recipe in ${CURRENT_RECIPES[@]}; do
	cd ${FEEDSTOCK_ROOT}/recipes/${recipe}
	boa build . --target-platform=emscripten-wasm32 -m ${EMFORGE_DIR}/conda_build_config.yaml
done

echo "Upload packages"

export QUETZ_API_KEY=$ANACONDA_API_TOKEN

if [ $(ls ${CONDA_BLD_PATH}/emscripten-wasm32/*.tar.bz2 | wc -l) -ne 0 ]; then
  quetz-client https://beta.mamba.pm/channels/robostack-wasm ${CONDA_BLD_PATH}/emscripten-wasm32/*.tar.bz2
fi

if [ $(ls ${CONDA_BLD_PATH}/linux-64/*.tar.bz2 | wc -l) -ne 0 ]; then
  quetz-client https://beta.mamba.pm/channels/robostack-wasm ${CONDA_BLD_PATH}/linux-64/*.tar.bz2
fi

if [ $(ls ${CONDA_BLD_PATH}/noarch/*.tar.bz2 | wc -l) -ne 0 ]; then
  quetz-client https://beta.mamba.pm/channels/robostack-wasm ${CONDA_BLD_PATH}/noarch/*.tar.bz2
fi

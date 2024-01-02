#!/bin/bash

export CONDA_BUILD_CROSS_COMPILATION="1"

echo "set_property(GLOBAL PROPERTY TARGET_SUPPORTS_SHARED_LIBS TRUE)"> $SRC_DIR/__vinca_shared_lib_patch.cmake
echo "set(CMAKE_SHARED_LIBRARY_CREATE_C_FLAGS \"-s SIDE_MODULE=1 -sWASM_BIGINT -s USE_PTHREADS=0 -s DEMANGLE_SUPPORT=1 -s ALLOW_MEMORY_GROWTH=1 \")">> $SRC_DIR/__vinca_shared_lib_patch.cmake
echo "set(CMAKE_SHARED_LIBRARY_CREATE_CXX_FLAGS \"-s SIDE_MODULE=1 -sWASM_BIGINT -s USE_PTHREADS=0 -s DEMANGLE_SUPPORT=1 -s ALLOW_MEMORY_GROWTH=1 \")">> $SRC_DIR/__vinca_shared_lib_patch.cmake
echo "set(CMAKE_STRIP FALSE)  # used by default in pybind11 on .so modules">> $SRC_DIR/__vinca_shared_lib_patch.cmake
echo "set(CMAKE_EXE_LINKER_FLAGS \"-sMAIN_MODULE=1 -sASSERTIONS=1 -fexceptions -lembind -sWASM_BIGINT -s USE_PTHREADS=0 -s DEMANGLE_SUPPORT=1 -sALLOW_MEMORY_GROWTH=1 -L$SRC_DIR/build -L$PREFIX/lib\")  # remove SIDE_MODULE from exe linker flags">> $SRC_DIR/__vinca_shared_lib_patch.cmake

export USE_WASM=ON
export EXTRA_CMAKE_ARGS=" \
    -DTHREADS_PREFER_PTHREAD_FLAG=TRUE\
    -DCMAKE_PREFIX_PATH=$PREFIX    \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DCMAKE_FIND_ROOT_PATH=$PREFIX \
    -DAMENT_PREFIX_PATH=$PREFIX \
    -DCMAKE_PROJECT_INCLUDE=$SRC_DIR/__vinca_shared_lib_patch.cmake \
  "

unset -f cmake

emcmake cmake \
    -G "Ninja" \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_INSTALL_SYSTEM_RUNTIME_LIBS_SKIP=True \
    -DBUILD_SHARED_LIBS=ON \
    -DBUILD_TESTING=OFF \
    $EXTRA_CMAKE_ARGS \
    $SRC_DIR/$PKG_NAME/src/work/wasm_cpp

cmake --build . --config Debug --target install --verbose

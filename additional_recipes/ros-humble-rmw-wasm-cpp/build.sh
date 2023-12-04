export CONDA_BUILD_CROSS_COMPILATION="1"

echo "set_property(GLOBAL PROPERTY TARGET_SUPPORTS_SHARED_LIBS TRUE)">> $SRC_DIR/__vinca_shared_lib_patch.cmake
echo "set(CMAKE_SHARED_LIBRARY_CREATE_C_FLAGS \"-s SIDE_MODULE=1\")">> $SRC_DIR/__vinca_shared_lib_patch.cmake
echo "set(CMAKE_SHARED_LIBRARY_CREATE_CXX_FLAGS \"-s SIDE_MODULE=1\")">> $SRC_DIR/__vinca_shared_lib_patch.cmake
echo "set(CMAKE_STRIP FALSE)  # used by default in pybind11 on .so modules">> $SRC_DIR/__vinca_shared_lib_patch.cmake

export USE_WASM=ON
export Python_EXECUTABLE="$BUILD_PREFIX/bin/python"
export Python_INCLUDE_DIR="$PREFIX/include/python3.11"
export Python_LIBRARY="$PREFIX/lib/python3.11"
export EXTRA_CMAKE_ARGS=" \
    -DTHREADS_PREFER_PTHREAD_FLAG=TRUE\
    -DPython_SITELIB=$SP_DIR       \
    -DCMAKE_PREFIX_PATH=$PREFIX    \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DCMAKE_FIND_ROOT_PATH=$PREFIX \
    -DAMENT_PREFIX_PATH=$PREFIX \
    -DCMAKE_PROJECT_INCLUDE=$SRC_DIR/__vinca_shared_lib_patch.cmake \
  "

unset -f cmake

emcmake cmake \
    -G "Ninja" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DPKG_CONFIG_EXECUTABLE=$PKG_CONFIG_EXECUTABLE \
    -DSETUPTOOLS_DEB_LAYOUT=OFF \
    -DCATKIN_SKIP_TESTING=$SKIP_TESTING \
    -DCMAKE_INSTALL_SYSTEM_RUNTIME_LIBS_SKIP=True \
    -DBUILD_SHARED_LIBS=ON  \
    -DBUILD_TESTING=OFF \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=$OSX_DEPLOYMENT_TARGET \
    $EXTRA_CMAKE_ARGS \
    $SRC_DIR/$PKG_NAME/src/work/rmw_wasm_cpp

cmake --build . --config Release --target install

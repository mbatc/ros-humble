# necessary for correctly linking SIP files (from python_qt_bindings)
export LINK=$CXX

export CONDA_BUILD_CROSS_COMPILATION="1"

echo "set_property(GLOBAL PROPERTY TARGET_SUPPORTS_SHARED_LIBS TRUE)">> $SRC_DIR/__vinca_shared_lib_patch.cmake
echo "set(CMAKE_SHARED_LIBRARY_CREATE_C_FLAGS \"-s SIDE_MODULE=1\")">> $SRC_DIR/__vinca_shared_lib_patch.cmake
echo "set(CMAKE_SHARED_LIBRARY_CREATE_CXX_FLAGS \"-s SIDE_MODULE=1\")">> $SRC_DIR/__vinca_shared_lib_patch.cmake
echo "set(CMAKE_STRIP FALSE)  # used by default in pybind11 on .so modules">> $SRC_DIR/__vinca_shared_lib_patch.cmake

export USE_WASM=ON
export Python_EXECUTABLE="$BUILD_PREFIX/bin/python"
export Python_INCLUDE_DIR="$PREFIX/include/python3.10"
export Python_LIBRARY="$PREFIX/lib/python3.10"
export EXTRA_CMAKE_ARGS=" \
    -DTHREADS_PREFER_PTHREAD_FLAG=TRUE\
    -DPython_SITELIB=$SP_DIR       \
    -DCMAKE_PREFIX_PATH=$PREFIX    \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DCMAKE_FIND_ROOT_PATH=$PREFIX \
    -DAMENT_PREFIX_PATH=$PREFIX \
    -DCMAKE_PROJECT_INCLUDE=$SRC_DIR/__vinca_shared_lib_patch.cmake \
  "

# see https://github.com/conda-forge/cross-python-feedstock/issues/24
if [[ "$CONDA_BUILD_CROSS_COMPILATION" == "1" ]]; then
  find $PREFIX/lib/cmake -type f -exec sed -i "s~\${_IMPORT_PREFIX}/lib/python${ROS_PYTHON_VERSION}/site-packages~${BUILD_PREFIX}/lib/python${ROS_PYTHON_VERSION}/site-packages~g" {} + || true
  find $PREFIX/share/rosidl* -type f -exec sed -i "s~$PREFIX/lib/python${ROS_PYTHON_VERSION}/site-packages~${BUILD_PREFIX}/lib/python${ROS_PYTHON_VERSION}/site-packages~g" {} + || true
  find $PREFIX/share/rosidl* -type f -exec sed -i "s~\${_IMPORT_PREFIX}/lib/python${ROS_PYTHON_VERSION}/site-packages~${BUILD_PREFIX}/lib/python${ROS_PYTHON_VERSION}/site-packages~g" {} + || true
  find $PREFIX/lib/cmake -type f -exec sed -i "s~message(FATAL_ERROR \"The imported target~message(WARNING \"The imported target~g" {} + || true
fi

unset -f cmake

emcmake cmake \
    -G "Ninja" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DPKG_CONFIG_EXECUTABLE=$PKG_CONFIG_EXECUTABLE \
    -DSETUPTOOLS_DEB_LAYOUT=OFF \
    -DCATKIN_SKIP_TESTING=$SKIP_TESTING \
    -DCMAKE_INSTALL_SYSTEM_RUNTIME_LIBS_SKIP=True \
    -DBUILD_SHARED_LIBS=ON \
    -DBUILD_TESTING=OFF \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=$OSX_DEPLOYMENT_TARGET \
    $EXTRA_CMAKE_ARGS \
    $SRC_DIR/$PKG_NAME/src/work/wasm_cpp

cmake --build . --config Release --target install

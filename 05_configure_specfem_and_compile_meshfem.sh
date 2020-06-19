#!/bin/bash

# Get compilation options
source 00_compilations_parameters.sh

# Specfem repository
cd specfem3d_globe
make clean
make realclean

# Change ADIOS BUFFER SIZE in constant.h.in
ini='  integer, parameter :: ADIOS_BUFFER_SIZE_IN_MB'
new='  integer, parameter :: ADIOS_BUFFER_SIZE_IN_MB = 15000'
sed -i "s/.*${ini}.*/$new/g" setup/constants.h.in

#ini='  double precision,parameter :: COURANT_SUGGESTED = 0.55d0'
#new='  double precision,parameter :: COURANT_SUGGESTED = 0.35d0'
#sed -i "s/.*${ini}.*/$new/g" setup/constants.h.in


if [ "$ASDF_WITH" == "--with-asdf" ]
then
    MPIFC="${HDF5_BIN}/h5pfc"
    MPICC="${HDF5_BIN}/h5pcc"
    echo "ASDF enabled."
    echo "MPIFC:____$MPIFC"
    echo "MPICC:____$MPICC"
else
    echo "No ASDF."
    echo "MPIFC:____$MPIFC"
    echo "MPICC:____$MPICC"
fi

# Configure
./configure CC=$CC CXX=$CXX FC=$FC MPIFC=$MPIFC \
CFLAGS="$CFLAGS" FCLAGS="$FCFLAGS" \
$CUDA_WITH CUDA_LIB="$CUDA_LIB" \
$ASDF_WITH ASDF_LIBS="$ASDF_LIBS" \
$ADIOS_WITH ADIOS_CONFIG="$ADIOS_CONFIG"

# Compilation
make meshfem3D -j
cd ..


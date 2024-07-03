#!/bin/bash

#########################
#     LOAD MODULES      #
#########################

# module load pgi/17.9/64
# module load openmpi/pgi-19.9/4.0.3rc1/64

NEED_ADIOS=false
NEED_ASDF=false
NEED_HDF5=false
NEED_PETSC=true
NEED_EMC=false


if $NEED_EMC
then 
    EMC_WITH="--with-emc"
else 
    EMC_WITH=""

if [[ $HOSTNAME == *"rhea"* ]]; then
    
    module purge
    module load gcc/4.8.5 openmpi/3.1.4
    CUDA_WITH="--with-cuda=cuda8"

elif [[ $HOSTNAME == *"login"* ]] || [[ $HOSTNAME == *"batch"* ]]; then
    
    module purge
    module load xl spectrum-mpi cuda cmake boost
    # NVIDIA Tesla V100 
    CUDA_WITH="--with-cuda=cuda8"

# Traverse and EMC that is compile with netcdf
elif [[ ( $HOSTNAME == *"traverse"* ) && ( $EMC_WITH == "--with-emc" ) ]]; then
    
    module purge
    module load anaconda3
    module load gcc-toolset/10
    module load openmpi/gcc/4.1.1/64
    module load hdf5/gcc/1.10.6 netcdf/gcc/hdf5-1.10.6/4.7.3
    module load cudatoolkit/11.1
    
    # NVIDIA Tesla V100 
    CUDA_WITH="--with-cuda=cuda9"

    # NETCDF SETUP
    NETCDF_WITH="--with-netcdf"
    NETCDF_INC="${NETCDFDIR}/include"
    NETCDF_LIBS="-L${NETCDFDIR}/lib"
    FCFLAGS="-lnetcdff ${FCFLAGS}"
    
# Only traverse
elif [[ $HOSTNAME == *"traverse"* ]]; then
    
    module purge
    module load anaconda3
    module load openmpi/gcc
    module load cudatoolkit
    conda activate gf
    # NVIDIA Tesla V100 
    CUDA_WITH="--with-cuda=cuda9"
    
elif [[ $HOSTNAME == *"tiger"* ]]; then
    
    module purge
    module load openmpi/gcc cudatoolkit/10.2

    # NVIDIA P100
    CUDA_WITH="--with-cuda=cuda8"


# DELLA and EMC that is compile with netcdf
elif [[ ( $HOSTNAME == *"della-gpu"* ) && ( $EMC_WITH == "--with-emc" ) ]]; then
    
    module purge
    #module load anaconda3/2021.11
    module load gcc/8 openmpi/gcc/4.1.2 cudatoolkit/11.7
    module load hdf5/gcc/1.10.6 netcdf/gcc/hdf5-1.10.6/4.7.4
    
    # NVIDIA Ampere A100 
    CUDA_WITH="--with-cuda=cuda11"

    # NETCDF SETUP
    NETCDF_WITH="--with-netcdf"
    NETCDF_INC="${NETCDFDIR}/include"
    NETCDF_LIBS="-L${NETCDFDIR}/lib"
    FCFLAGS="-lnetcdff ${FCFLAGS}"
    
elif [[ $HOSTNAME == *"della-gpu"* ]]; then

    module purge
    module load anaconda3/2021.11
    
    conda activate gf
    # NVIDIA A100E 
    CUDA_WITH="--with-cuda=cuda11"
 
    
else
    echo "HOST: ${HOSTNAME} not recognized."
fi



#########################
#   DIRECOTRIES INFOS   #
#########################
ROOT_DIR=$(pwd)
PACKAGES="${ROOT_DIR}/packages"
PATH_CUDA=$(which nvcc)
ASDF_DIR="${PACKAGES}/asdf-library"
ADIOS_DIR="${PACKAGES}/adios"
HDF5_DIR="${PACKAGES}/hdf5"
PETSC_DIR="${PACKAGES}/petsc"

#########################
# Green Function stuff  #
#########################

export RECIPROCAL=True
export FORWARD_TEST=True

#########################
# Compilation variables #
#########################

# C/C++ compiler
CC=gcc
CXX=g++
MPICC=$(which mpicc)

# Fortran compiler
FC=gfortran
MPIFC=mpif90

# Compiler flags the CFLAG "-std=c++11" avoids the '''error: identifier "__ieee128" is undefined'''
# gfortran     ifort         effect
# ------------------------------------------------------
# -g           -g            Stores the code inside the binary
# -O0          -O0           Disables optimisation
# -fbacktrace  -traceback    More informative stack trace
# -Wall        -warn all     Enable all compile time warnings
# -fcheck=all  -check all    Enable run time checks


CFLAGS=""
#FCFLAGS="-g -O0 -fbacktrace -Wall -fcheck=all"
FCFLAGS="${FCFLAGS} -g -O0 -fbacktrace"

# CUDA (here CUDA 5 because my GPU cannot support more, poor boy)

CUDA_LIB="${PATH_CUDA/bin\/nvcc/lib64}"

# SPECFEM
SPECFEM_DIR="${ROOT_DIR}/specfem3d_globe"
SPECFEM_LINK="git@github.com:williameaton/specfem3d_globe.git"
SPECFEM_BRANCH="devel"


# HDF5
HDF5_LINK="https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.12/hdf5-1.12.0/src/hdf5-1.12.0.tar.gz"
HDF5_DESTDIR="${HDF5_DIR}/build"
HDF5_FC="${HDF5_DESTDIR}/bin/h5pfc"
HDF5_CC="${HDF5_DESTDIR}/bin/h5pcc"
MPIFC_HDF5=$HDF5_FC
export PATH=$PATH:${HDF5_DESTDIR}/bin

# ASDF
if $NEED_ASDF
then 
    echo "Using ASDF"
    ASDF_WITH="--with-asdf"
    ASDF_LINK="https://github.com/SeismicData/asdf-library.git"
    ASDF_DESTDIR="${ASDF_DIR}/build"
    ASDF_LIBS="-L${ASDF_DESTDIR}/usr/local/lib64 -lasdf"
else 
    echo "Not using ASDF"
    ASDF_WITH="" 
fi 


# PETSC
PETSC_LINK="https://gitlab.com/petsc/petsc.git petsc"
PETSC_DESTDIR="${PETSC_DIR}/build"
PETSC_LIB="${ASDF_DESTDIR}/lib"
PETSC_INC="${ASDF_DESTDIR}/include"
PETSC_WITH="--with-petsc"

# ADIOS
ADIOS_VERSION="2"
ADIOS_BUILD="${PACKAGES}/adios-build"
ADIOS_INSTALL="${PACKAGES}/adios-install"

# ADIOS version specific things
if [ $ADIOS_VERSION == "2" ]
then
    ADIOS_WITH="--with-adios2"
    ADIOS_CONFIG="${ADIOS_INSTALL}/bin/adios2_config"
    ADIOS_LINK="https://github.com/ornladios/ADIOS2.git"
else
    ADIOS_WITH="--with-adios"
    ADIOS_CONFIG="${ADIOS_INSTALL}/bin/adios_config"
    ADIOS_LINK="http://users.nccs.gov/~pnorbert/adios-1.13.1.tar.gz"
fi

if $NEED_ADIOS
then
    echo "Using ADIOS"
    export PATH=$PATH:${ADIOS_INSTALL}/bin
else 
    echo "Not using ADIOS"
    ADIOS_WITH=""
    ADIOS_CONFIG=""
fi 




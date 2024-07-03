#!/bin/bash

# Get compiler options
source 00_compilations_parameters.sh

cd $PETSC_DIR

# We need to add the openmpi library explicitly to the path: 
openmpilib=$(ompi_info > infofromompi &&  grep -o "[-]-libdir=[^']*" infofromompi && rm infofromompi)
# Strip out the part before 
openmpilib=${openmpilib#*=}

export LD_LIBRARY_PATH=$openmpilib/:$LD_LIBRARY_PATH

./configure --with-cc=$MPICC --with-fc=$MPIFC  --with-mpi=yes --prefix=$PETSC_DESTDIR

make && make install 

cd $ROOT_DIR

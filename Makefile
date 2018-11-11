# Serial Fortran 90 compiler.  Default is "f90".
export F90 := ifort
# MPI Fortran 90 compiler.  Default is "mpif90".
export MPF90 := mpiifort
# MPI Fortran 77 compiler.  Default is "mpif77".
export MPF77 := mpiifort
# MPI C++ compiler.  Default is "mpicxx".
export MPCC := mpiicc
# =========== Compiler Optimizations =============
# Fortran 90 compiler flags
export F90FLAGS := -O3 -traceback -qopenmp -qopt-report=5 -parallel
# Fortran 77 compiler flags
export FFLAGS := -O2
# C compiler flags.
export CFLAGS := -O3
# Extra flags used for linking
export LDFLAGS := -lm -qopenmp -cxxlib #-prof-file prof.dat -prof-dir . -profile-functions -profile-loops=all
# ============== Language Mixing =================
export MPFCLIBS := -qopenmp
# ============== Fortran Features ================
# Set this variable to 1 if the fortran compiler
# produces module files with capitalization (*.MOD)
# instead of lowercase (*.mod).
#export FORTRAN_UPPER := 1
export LOCAL=/mn/stornext/u3/hke/owl/local
# =============== CFITSIO Linking ================
# The include and linking commands for cfitsio.
export CFITSIO_INCLUDE :=
export CFITSIO_LINK := -L$(LOCAL)/lib -lcfitsio
# =============== SHARP Linking ================
# The include and linking commands for cfitsio.
export SHARP_INCLUDE :=
export SHARP_LINK := -L/mn/stornext/u3/hke/owl/local/src/libsharp/auto/lib -lsharp
# =============== LAPACK Linking =================
# The include and linking commands for LAPACK.
MKLPATH := $(MKLROOT)
export LAPACK_INCLUDE :=
export LAPACK_LINK := -shared-intel -Wl,-rpath,$(MKLPATH)/lib/intel64 -L$(MKLPATH)/lib/intel64  -lmkl_intel_lp64 -lmkl_intel_thread -lmkl_core -lpthread
# ================ Healpix linking ================

export HEALPIX := /mn/stornext/u3/hke/owl/local/src/dagsshealpix
export HEALPIX=/mn/stornext/u3/hke/owl/local/src/dagsshealpix
export HEALPIX_INCLUDE := -I$(HEALPIX)/include
export HEALPIX_LINK := -L$(HEALPIX)/lib -lhealpix
#export HEALPIX_INCLUDE := -I/usit/titan/u1/sigurdkn/local/include
#export HEALPIX_LINK := -L/usit/titan/u1/sigurdkn/local/lib -lhealpix
#export HEALPIX_INCLUDE := -I$(LOCAL)/include
#export HEALPIX_LINK := -L$(LOCAL)/lib -lhealpix
#export HEALPIX_INCLUDE := -I/usit/titan/u1/hke/local/src/Healpix_2.10/src/f90/mod
#export HEALPIX_LINK := -L/usit/titan/u1/hke/local/src/Healpix_2.10/src/f90/mod -lhealpix
# =============== HDF ============================
export LOCAL=/mn/stornext/u3/hke/owl/local
export HDF_LINK := -L$(LOCAL)/lib -lhdf5_fortran -lhdf5
export HDF_LINK_CPP := -L$(LOCAL)/lib -lhdf5_cpp -lhdf5
export HDF_INCLUDE := -I$(LOCAL)/include

export F90COMP := $(F90FLAGS) $(LAPACK_INCLUDE) $(CFITSIO_INCLUDE) $(HEALPIX_INCLUDE) $(HDF_INCLUDE)
export FCOMP := $(FFLAGS)  $(LAPACK_INCLUDE) $(CFITSIO_INCLUDE) $(HEALPIX_INCLUDE)
export CCOMP := $(CFLAGS)  $(LAPACK_INCLUDE) $(CFITSIO_INCLUDE) $(HEALPIX_INCLUDE)

export COMMANDER_LINK := -L/mn/stornext/u3/trygvels/compsep/Commander/commander1/src/commander -lcommander
export LINK := -L. -lnewdgrade $(COMMANDER_LINK) $(SHARP_LINK) $(HEALPIX_LINK) $(CFITSIO_LINK) $(LAPACK_LINK) $(HDF_LINK) $(LDFLAGS) $(F90OMPFLAGS) $(OBS)

export OBJDIR := /mn/stornext/u3/trygvels/compsep/Commander/src/commander/

COBJS  := hashtbl.o comm_hdf_mod.o sharp.o sort_utils.o math_tools.o locate_mod.o spline_1D_mod.o \
        comm_system_backend.o comm_system_mod.o comm_map_mod.o \
        comm_defs.o comm_utils.o \
        comm_shared_output_mod.o comm_status_mod.o \
        comm_param_mod.o comm_comp_mod.o

all : newdgrade # commander # sharp_test

comm_map_mod.o :           sharp.o comm_hdf_mod.o comm_param_mod.o
comm_hdf_mod.o :           comm_utils.o
comm_param_mod.o :         comm_utils.o comm_status_mod.o hashtbl.o
comm_utils.o :             comm_defs.o spline_1D_mod.o sort_utils.o comm_system_mod.o sharp.o
spline_1D_mod.o :          locate_mod.o
locate_mod.o :             math_tools.o
comm_status_mod.o :        comm_shared_output_mod.o
comm_shared_output_mod.o : comm_system_mod.o
comm_system_mod.o :        comm_system_backend.o

newdgrade : libnewdgrade.a newdgrade.o
	$(MPF90) -o newdgrade newdgrade.o $(LINK) $(MPFCLIBS)

sharp_test : sharp.o sharp_test.o
	$(MPF90) -o sharp_test sharp_test.o sharp.o $(LINK) $(MPFCLIBS)

export AR := ar
export ARFLAGS := crv
export RANLIB := ranlib

libnewdgrade.a : $(addprefix $(OBJDIR),$(COBJS))
	$(AR) $(ARFLAGS) libnewdgrade.a $(addprefix $(OBJDIR),$(COBJS))
	$(RANLIB) libnewdgrade.a

%.o : %.F90
	$(MPF90) $(F90COMP) -c $<

%.o : %.f90
	$(MPF90) $(F90COMP) -c $< -I$(OBJDIR)

%.o : %.f
	$(MPF77) $(FCOMP) -c $<

%.o : %.cpp
	$(MPCXX) $(CXXCOMP) -c $<

%.f90 : %.f90.in
	$(TEMPITA) < "$<" > "$@"

clean :
	@rm -f *.o *.mod *.MOD *.a *~ newdgrade

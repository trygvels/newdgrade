program newdgrade ! Write your own comm_data_mod
  use mpi
  use iso_c_binding, only : c_ptr, c_double
  use comm_map_mod
  use healpix_types
  use udgrade_nr

  implicit none
  integer :: ierr, i, j, r, i_ring, nrings
  integer :: my_id   ! my processor number  (rank)
  integer :: n_procs ! Number of processors (Size)
  class(comm_mapinfo), pointer :: info, info_out
  class(comm_map),     pointer :: map, map_out
  real(dp), allocatable, dimension(:,:) :: m_in, m_out, buffer 
  integer, allocatable, dimension(:) :: ringpix, rpix
  character(len=1024) :: inside, outside


  call mpi_init(ierr)
  call mpi_comm_size(MPI_COMM_WORLD, n_procs, ierr)
  call mpi_comm_rank(MPI_COMM_WORLD, my_id, ierr)

  !! Constructing info for data variable, #nside, lmax, nmaps, polarization
  info => comm_mapinfo(mpi_comm_world, 4, 5, 1, .false.)
  info_out => comm_mapinfo(mpi_comm_world, 2, 5, 1, .false.)
  map  => comm_map(info, 'cmb_n4.fits')
  map_out => comm_map(info_out)


  ! Ring pixel number (Maybe column 1 is number, and column 2 is pixels?)
  nrings = 4*info%nside-1 ! Number of rings per nside
  allocate(ringpix(1:nrings))
  ringpix(1) = 0
  
  do i_ring = 2, nrings    
     if ((i_ring < info%nside+1)) then
        ! north and south hemisphere 
        ringpix(i_ring) = ringpix(i_ring-1) + 4*(i_ring - 1)
     else if (i_ring > nrings - info%nside + 1) then
        ringpix(i_ring) = ringpix(i_ring-1) + 4*(nrings - (i_ring -1) + 1)
     else
        ! equatorial
        ringpix(i_ring) = ringpix(i_ring-1)+4*info%nside
     end if
  end do
  
  ! Allocate input map array 
  allocate(m_in(0:info%npix-1,info%nmaps))
  ! Allocate output map array 
  allocate(m_out(0:info_out%npix-1,info_out%nmaps))
    ! Allocate buffer map array 
  allocate(buffer(0:map_out%info%npix-1,map_out%info%nmaps))
  m_in                  = 0.d0  ! Sets all values of array to 0
  m_in(info%pix,:) = map%map    ! Puts map into a sparse array per thread
  ! Remove data in specific rings (For testing)
  do i = 1, size(map%info%rings)   ! Rings per thread
     r = map%info%rings(i)         ! Ring number
     ! k = 0
     ! do j = ringpix(r), ringpix(r+1)-1 
     !    rpix(0) =
     ! end do
     if (r < nrings) then
        rpix = (/ (j, j=ringpix(r),ringpix(r+1)-1) /) ! Returns sequence of pixel values for ring
     else
        rpix = (/ (j, j=ringpix(r),map%info%npix-1) /)
     end if
     !write(*,*) rpix, "::::", ringpix(r), ringpix(r+1) -1, -(ringpix(r)- ringpix(r+1)) 
     ! In south
     if (r > 3*map%info%nside-2) then
        m_in(rpix,:) = 0.d0
             
     ! In equatorial 
     else if (r < map%info%nside+2) then
       m_in(rpix,:) = 0.d0
    end if
     ! In north  
     !else
     !   m_in(rpix,:) = 0.d0
     !endif
  
  enddo 

 
  map%map = m_in(map%info%pix,:)

  call udgrade_ring(m_in, map%info%nside, m_out, map_out%info%nside)
  call mpi_allreduce(m_out, buffer, size(m_out), MPI_DOUBLE_PRECISION, MPI_SUM, info%comm, ierr)
  map_out%map = buffer(map_out%info%pix,:)

  
  ! Write inmap
  write(inside, "(I1)") info%nside
  call map%writeFITS("test_n"//trim(inside)//".fits")
  ! write outmap
  write(outside, "(I1)") info_out%nside
  call map_out%writeFITS("test_n"//trim(outside)//".fits")
  
end program



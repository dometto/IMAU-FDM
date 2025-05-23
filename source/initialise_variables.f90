module initialise_variables
    !*** Subroutines for allocating memory and assigning initial values to variables ***!

    implicit none

    private

    public :: Define_Constants, Get_All_Command_Line_Arg, Get_Model_Settings_and_Forcing_Dimensions, Define_Paths, Init_TimeStep_Var, Calc_Output_Freq, &
        Init_Prof_Var, Init_Output_Var, Alloc_Forcing_Var

    
contains


! *******************************************************

subroutine Define_Constants(rhoi, R, pi, Ec, Eg, g, Lh)
    !*** Define physical constants ***!
    
    double precision, intent(out) :: rhoi, R, pi, Ec, Eg, g, Lh
    
    pi = asin(1.)*2         ! pi = 3.1415
    R = 8.3145              ! gas constant [J mole-1 K-1]
    g = 9.81                ! gravitational acceleration [m s-2]
    rhoi = 917.             ! density of ice [kg m-3]
    ! Tmelt = 273.15          ! melting point of ice [K]
    Ec = 60000.             ! activation energy for creep [J mole-1]
    !Ec2 = 49000.            ! activation energy grain boundary diffusion [J mole-1]
    Eg = 42400.             ! activation energy for grain growth [J mole-1]
    Lh = 333500.            ! latent heat of fusion [J kg-1]
    ! kg = 1.3E-7             ! rate constant for grain growth [m2 s-1]
    ! seconds_per_year = 3600.*24.*365.25   ! seconds per year [s]
    ! NaN_value = 9.96921e+36 ! missing value for doubles as used in the NCL scripts
    ! rgrain_refreeze = 1.E-3    ! grain size refrozen ice [m]
    ! Nlat_timeseries = 566           ! size of forcing "strips", equal to Nlat and Nlon if not cut up
    ! Nlon_timeseries = 6
end subroutine Define_Constants


! *******************************************************


subroutine Get_All_Command_Line_Arg(username, point_numb, domain, prefix_output, project_name, restart_type)
    !*** Get all command line arguments ***!

    ! declare arguments
    character*255, intent(out) :: username, point_numb, domain, prefix_output, project_name, restart_type

    ! 1: ECMWF username (e.g. nmg)
    ! 2: Simulation number, corresponding to the line number in the IN-file.
    ! 3: Domain name, similar to the RACMO forcing (e.g. ANT27)
    ! 4: General part of output filename
    ! 5: Optional, name of the initialization file
    call get_command_argument(1, username)
    call get_command_argument(2, point_numb)
    call get_command_argument(3, domain)
    call get_command_argument(4, prefix_output)
    call get_command_argument(5, project_name)
    call get_command_argument(6, restart_type)
    
end subroutine Get_All_Command_Line_Arg


subroutine Get_Model_Settings_and_Forcing_Dimensions(dtSnow, nyears, nyearsSU, dtmodelImp, dtmodelExp, ImpExp, dtobs, ind_z_surf, startasice, &
    beginT, writeinprof, writeinspeed, writeindetail, proflayers, detlayers, detthick, dzmax, initdepth, th, &
    lon_current, lat_current, Nlon, Nlat, Nt_forcing, point_numb, username, domain, project_name)
    !*** Load model settings from file ***!
    
    ! declare arguments
    integer, intent(out) :: writeinprof, writeinspeed, writeindetail, dtSnow, nyears, nyearsSU, dtmodelImp, &
        dtmodelExp, ImpExp, dtobs, ind_z_surf, startasice, beginT, proflayers, detlayers, Nlon, Nlat, Nt_forcing
    double precision, intent(out) :: dzmax, initdepth, th, lon_current, lat_current, detthick
    character*255, intent(in) :: point_numb, username, domain, project_name

    ! declare local variables
    character*255 :: pad
    integer :: NoR

    pad = "/ec/res4/scratch/"//trim(username)//"/"//trim(project_name)//"/ms_files/"
    
    print *, "Path to input settings file:"
    print *, trim(pad)//"model_settings_"//trim(domain)//"_"//trim(point_numb)//".txt"
    print *, " "

    open(unit=12, file=trim(pad)//"model_settings_"//trim(domain)//"_"//trim(point_numb)//".txt")

    ! read model settings and forcing dimensions
    read (12,*)
    read (12,*)
    read (12,*) nyears              ! simulation time [yr]
    read (12,*) nyearsSU            ! simulation time during the spin up period [yr]
    read (12,*) dtmodelExp          ! time step in model with explicit T-scheme [s] 
    read (12,*) dtmodelImp          ! time step in model with implicit T-scheme [s]
    read (12,*) ImpExp              ! Impicit or Explicit scheme (1=Implicit/fast, 2= Explicit/slow)
    read (12,*) dtobs               ! time step in input data [s]
    read (12,*) dtSnow              ! duration of running average of variables used in snow parameterisation [s]
    read (12,*)
    read (12,*) dzmax               ! vertical model resolution [m]
    read (12,*) initdepth           ! initial depth of firn profile [m]
    read (12,*) th                  ! theta (if theta=0.5 , it is a Crank Nicolson scheme) 
    read (12,*) startasice          ! indicates the initial rho-profile (1=linear, 2=ice)
    read (12,*) beginT              ! indicates the inital T-profile (0=winter, 1=summer, 2=linear)
    read (12,*) NoR                 ! number of times the data series is repeated for the initial rho profile is constructed
    read (12,*) 
    read (12,*) writeinspeed        ! frequency of writing speed components to file
    read (12,*) writeinprof         ! frequency of writing of firn profiles to file
    read (12,*) proflayers          ! number of output layers in the prof file
    read (12,*) writeindetail       ! frequency of writing to detailed firn profiles to file
    read (12,*) detlayers           ! number of output layers in the detailed prof file
    read (12,*) detthick            ! thickness of output layer in the detailed prof file
    read (12,*)
    read (12,*) lon_current         ! Lon; indicates the longitude gridpoint
    read (12,*) lat_current         ! Lat; indicates the latitude gridpoint
    read (12,*)
    read (12,*) Nlon                 ! Number of longitude points in forcing
    read (12,*) Nlat                 ! Number of latitude points in forcing
    read (12,*) Nt_forcing           ! Number of timesteps in forcing


    ind_z_surf = nint(initdepth/dzmax)  ! initial amount of vertical layers

    close(12)
    
    print *, "Loaded model settings"
    print *, " "

end subroutine Get_Model_Settings_and_Forcing_Dimensions


! *******************************************************


subroutine Define_Paths(username, prefix_output, point_numb, path_settings, path_forcing_dims, path_forcing_mask, path_forcing_averages, path_forcing_timeseries, &
        path_in_restart, path_out_restart, path_out_ini, path_out_1d, path_out_2d, path_out_2ddet, fname_settings, fname_forcing_dims, fname_mask, &
        suffix_forcing_averages, prefix_forcing_timeseries, fname_out_restart, fname_out_ini, fname_out_1d, fname_out_2d, fname_out_2ddet, &
        Nlat_timeseries, Nlon_timeseries, project_name, domain)
    
    !*** Definition of all paths used to read in or write out files ***!

    ! declare arguments
    integer, intent(out) :: Nlat_timeseries, Nlon_timeseries
    character*255, intent(in) :: username, prefix_output, point_numb, project_name, domain
    character*255, intent(out) :: path_settings, path_forcing_dims, path_forcing_mask, path_forcing_averages, path_forcing_timeseries, path_in_restart, path_out_restart, &
        path_out_ini, path_out_1d, path_out_2d, path_out_2ddet, fname_settings, fname_forcing_dims, fname_mask, suffix_forcing_averages, prefix_forcing_timeseries, &
        fname_out_restart, fname_out_ini, fname_out_1d, fname_out_2d, fname_out_2ddet

    ! define local variables
    character*255 :: forcing, domain_name

    ! define paths

    if ( trim(domain) == "Greenland" ) then
        domain_name = "FGRN055"
    end if

    forcing = "era055"

    print *, "project name: ", project_name
    
    path_settings = "/ec/res4/scratch/"//trim(username)//"/"//trim(project_name)//"/ms_files/"
    path_forcing_dims = "/perm/"//trim(username)//"/code/IMAU-FDM/reference/"//trim(domain_name)//"/"
    path_forcing_mask = "/perm/"//trim(username)//"/code/IMAU-FDM/reference/"//trim(domain_name)//"/"
    path_forcing_averages = "/ec/res4/scratch/"//trim(username)//"/"//trim(domain_name)//"_"//trim(forcing)//"/input/averages/"
    path_forcing_timeseries = "/ec/res4/scratch/"//trim(username)//"/"//trim(domain_name)//"_"//trim(forcing)//"/input/timeseries/"
    path_in_restart = "/ec/res4/scratch/"//trim(username)//"/restart/"//trim(project_name)//"/"
    path_out_restart = "/ec/res4/scratch/"//trim(username)//"/restart/"//trim(project_name)//"/"
    path_out_ini = "/ec/res4/scratch/"//trim(username)//"/restart/"//trim(project_name)//"/"
    path_out_1d = "/ec/res4/scratch/"//trim(username)//"/"//trim(project_name)//"/output/"
    path_out_2d = "/ec/res4/scratch/"//trim(username)//"/"//trim(project_name)//"/output/"
    path_out_2ddet = "/ec/res4/scratch/"//trim(username)//"/"//trim(project_name)//"/output/"

    ! define filenames
    fname_settings = "model_settings_Greenland_"//trim(point_numb)//".txt"
    fname_forcing_dims = "input_settings_"//trim(domain_name)//".txt"
    fname_mask = trim(domain_name)//"_Masks.nc"
    suffix_forcing_averages = "_"//trim(domain_name)//"_"//trim(forcing)//"-1939_1940-1970_ave.nc"
    prefix_forcing_timeseries = "_"//trim(domain_name)//"_"//trim(forcing)//"_1939-2023_p"
    fname_out_restart = trim(prefix_output)//"_restart_"//trim(point_numb)//".nc"
    fname_out_ini = trim(prefix_output)//"_ini_"//trim(point_numb)//".nc"
    fname_out_1d = trim(prefix_output)//"_1D_"//trim(point_numb)//".nc"
    fname_out_2d = trim(prefix_output)//"_2D_"//trim(point_numb)//".nc"
    fname_out_2ddet = trim(prefix_output)//"_2Ddetail_"//trim(point_numb)//".nc"
    Nlat_timeseries = 566           ! size of forcing "strips", equal to Nlat and Nlon if not cut up
    Nlon_timeseries = 6

end subroutine Define_Paths


! *******************************************************


subroutine Init_TimeStep_Var(dtobs, dtmodel, dtmodelImp, dtmodelExp, Nt_forcing, Nt_model_interpol, Nt_model_tot, Nt_model_spinup, ImpExp, nyearsSU)
    !*** Initialise time step variables ***!

    ! declare arguments
    integer, intent(in) :: dtobs, dtmodelImp, dtmodelExp, nyearsSU, Nt_forcing, ImpExp
    integer, intent(out) :: Nt_model_interpol, Nt_model_tot, Nt_model_spinup
    integer, intent(inout) :: dtmodel

    if (ImpExp == 2) then
        dtmodel = dtmodelExp
    else
        dtmodel = dtmodelImp
    endif

    ! Number of IMAU-FDM time steps per forcing time step
    Nt_model_interpol = dtobs/dtmodel
    ! Total number of IMAU-FDM time steps
    Nt_model_tot = Nt_forcing*Nt_model_interpol
    ! Total number of time steps per spin-up period
    ! Nt_model_spinup = INT( REAL(Nt_model_tot)*(REAL(nyearsSU)*365.25*24.*3600.)/(REAL(Nt_forcing*dtobs)) )
    Nt_model_spinup = INT( (REAL(nyearsSU)*365.25*24.*3600.)/(REAL(dtmodel)) )
    if (Nt_model_spinup > Nt_model_tot) Nt_model_spinup = Nt_model_tot

    print *, "dtmodel: ", dtmodel
    print *, 'Nt_model_interpol: ', Nt_model_interpol
    print *, 'Nt_model_tot: ', Nt_model_tot
    print *, 'Nt_model_spinup: ', Nt_model_spinup
    print *, ' '

end subroutine Init_TimeStep_Var


subroutine Calc_Output_Freq(dtmodel, nyears, writeinprof, writeinspeed, writeindetail, numOutputProf, &
    numOutputSpeed, numOutputDetail, outputProf, outputSpeed, outputDetail)
    !*** Calculate the output frequency ***!

    ! declare arguments
    integer, intent(in) :: dtmodel, nyears, writeinprof, writeinspeed, writeindetail
    integer, intent(out) :: numOutputProf, numOutputSpeed, numOutputDetail
    integer, intent(out) :: outputProf, outputSpeed, outputDetail
    integer, parameter :: double_kind = selected_real_kind( p=15, r=200 )

    integer(double_kind) :: spy, outputProf2, outputProf2_num

    numOutputProf = writeinprof / dtmodel
    numOutputSpeed = writeinspeed / dtmodel
    numOutputDetail = writeindetail / dtmodel
    spy = 3600.*24.*365.
    print *, "spy: ", spy
    
    outputProf = INT( REAL(nyears * spy) / REAL(writeinprof))
    outputSpeed = INT( REAL(nyears * spy) / REAL(writeinspeed))
    outputDetail = INT( REAL(nyears * spy) / REAL(writeindetail))
    
    outputProf2_num = nyears * spy
    outputProf2 = outputProf2_num / writeinprof

    print *, " "
    print *, "Output variables"
    print *, "Prof, Speed, Detail"
    print *, "writein...", writeinprof, writeinspeed, writeindetail
    print *, "numOutput...", numOutputProf, numOutputSpeed, numOutputDetail
    print *, "output...", outputProf, outputSpeed, outputDetail
    print *, " "

end subroutine Calc_Output_Freq


! *******************************************************


subroutine Init_Prof_Var(ind_z_surf, Rho, M, T, Depth, Mlwc, DZ, DenRho, Refreeze, Year, DZ_max)
    !*** Initialise firn profile variables with zeros ***!

    ! declare arguments
    integer, intent(in) :: ind_z_surf
    double precision, intent(in) :: DZ_max
    double precision, dimension(:), intent(out) :: Rho, M, T, Depth, Mlwc, DZ, DenRho, Refreeze, Year

    ! declare local variables
    integer :: ind_z

    Rho(:) = 0.
    M(:) = 0.
    T(:) = 0.
    Depth(:) = 0.
    Mlwc(:) = 0.
    DZ(:) = 0.
    DenRho(:) = 0.
    Refreeze(:) = 0.
    Year(:) = 0.
    
    DZ(1:ind_z_surf) = DZ_max

    Year(1:ind_z_surf) = -999.
    Depth(ind_z_surf) = 0.5*DZ_max
    do ind_z = (ind_z_surf-1), 1, -1
        Depth(ind_z) = Depth(ind_z+1) + 0.5*DZ(ind_z+1) + 0.5*DZ(ind_z)
    enddo

end subroutine Init_Prof_Var


! *******************************************************


subroutine Init_Output_Var(out_1D, out_2D_dens, out_2D_temp, out_2D_lwc, out_2D_depth, out_2D_dRho, out_2D_year, &
        out_2D_det_dens, out_2D_det_temp, out_2D_det_lwc, out_2D_det_refreeze, outputSpeed, outputProf, outputDetail, &
        proflayers, detlayers)
    !*** Initialise output variables with NaNs ***!

    ! declare arguments
    integer, intent(in) :: outputSpeed, outputProf, outputDetail, proflayers, detlayers
    double precision, dimension(:,:), allocatable, intent(out) :: out_1D, out_2D_dens, out_2D_temp, out_2D_lwc, out_2D_depth, out_2D_dRho, &
        out_2D_year, out_2D_det_dens, out_2D_det_temp, out_2D_det_lwc, out_2D_det_refreeze

    ! declare local variables
    double precision :: NaN_value

    ! This is the missing value for doubles as used in the NCL scripts
    NaN_value = 9.96921e+36

    ! allocate memory to variables
    allocate(out_1D((outputSpeed+150), 18))
    allocate(out_2D_dens((outputProf+150), proflayers))
    allocate(out_2D_temp((outputProf+150), proflayers))
    allocate(out_2D_lwc((outputProf+150), proflayers))
    allocate(out_2D_depth((outputProf+150), proflayers))
    allocate(out_2D_dRho((outputProf+150), proflayers))
    allocate(out_2D_year((outputProf+150), proflayers))
    allocate(out_2D_det_dens((outputDetail+150), detlayers))
    allocate(out_2D_det_temp((outputDetail+150), detlayers))
    allocate(out_2D_det_lwc((outputDetail+150), detlayers))
    allocate(out_2D_det_refreeze((outputDetail+150), detlayers))
    
    ! Set missing value
    out_1D(:,:) = NaN_value
    out_2D_dens(:,:) = NaN_value
    out_2D_temp(:,:) = NaN_value
    out_2D_lwc(:,:) = NaN_value
    out_2D_depth(:,:) = NaN_value
    out_2D_dRho(:,:) = NaN_value
    out_2D_year(:,:) = NaN_value
    out_2D_det_dens(:,:) = NaN_value
    out_2D_det_temp(:,:) = NaN_value
    out_2D_det_lwc(:,:) = NaN_value
    out_2D_det_refreeze(:,:) = NaN_value

end subroutine Init_Output_Var


! *******************************************************

subroutine Alloc_Forcing_Var(SnowMelt, PreTot, PreSol, PreLiq, Sublim, TempSurf, SnowDrif, FF10m, AveTsurf, LSM, ISM, &
    Latitude, Longitude, AveAcc, AveWind, AveMelt, TempFM, PsolFM, PliqFM, SublFM, MeltFM, DrifFM, Rho0FM, &
    Nt_forcing, Nt_model_tot, Nlon, Nlat)
    !*** Allocate memory to forcing variables ***!

    ! declare arguments
    integer, intent(in) :: Nt_forcing, Nt_model_tot, Nlon, Nlat
    double precision, dimension(:), allocatable, intent(out) :: SnowMelt, PreTot, PreSol, PreLiq, Sublim, TempSurf, SnowDrif, FF10m
    double precision, dimension(:), allocatable, intent(out) :: MeltFM, PsolFM, PliqFM, SublFM, TempFM, DrifFM, Rho0FM
    double precision, dimension(:,:), allocatable, intent(out) :: AveTsurf, LSM, ISM, Latitude, Longitude, AveAcc, AveWind, AveMelt

    ! Adjust matrices to correct dimensions of the netCDF files

    ! Forcing time series variables
    allocate(SnowMelt(Nt_forcing))
    allocate(PreTot(Nt_forcing))
    allocate(PreSol(Nt_forcing))
    allocate(PreLiq(Nt_forcing))
    allocate(Sublim(Nt_forcing))
    allocate(TempSurf(Nt_forcing))
    allocate(SnowDrif(Nt_forcing))
    allocate(FF10m(Nt_forcing))
    
    ! Averaged variables
    allocate(AveTsurf(Nlon,Nlat))
    allocate(LSM(Nlon,Nlat))
    allocate(ISM(Nlon,Nlat))
    allocate(Latitude(Nlon,Nlat))
    allocate(Longitude(Nlon,Nlat))
    allocate(AveAcc(Nlon,Nlat))
    allocate(AveWind(Nlon,Nlat))
    allocate(AveMelt(Nlon,Nlat))

    ! Interpolated forcing time series variables
    allocate(MeltFM(Nt_model_tot))
    allocate(PsolFM(Nt_model_tot))
    allocate(PliqFM(Nt_model_tot))
    allocate(SublFM(Nt_model_tot))
    allocate(TempFM(Nt_model_tot))
    allocate(DrifFM(Nt_model_tot))
    allocate(Rho0FM(Nt_model_tot))
    
end subroutine Alloc_Forcing_Var

    
end module initialise_variables

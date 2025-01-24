MODULE infmod
   !!======================================================================
   !!                       ***  MODULE  infmod  ***
   !! Machine Learning Inferences : manage connexion with external ML codes 
   !!======================================================================
   !! History :  4.2.1  ! 2023-09  (A. Barge)  Original code
   !!----------------------------------------------------------------------

   !!----------------------------------------------------------------------
   !!   naminf          : machine learning models formulation namelist
   !!   inferences_init : initialization of Machine Learning based models
   !!   inferences      : ML based models
   !!   inf_snd         : send data to external trained model
   !!   inf_rcv         : receive inferences from external trained model
   !!----------------------------------------------------------------------
   USE oce             ! ocean fields
   USE dom_oce         ! ocean domain fields
   USE sbc_oce         ! ocean surface fields
   USE inffld          ! working fields for inferences models
   USE cpl_oasis3      ! OASIS3 coupling
   USE timing
   USE iom
   USE in_out_manager
   USE lib_mpp

   IMPLICIT NONE
   PRIVATE

   PUBLIC inf_alloc          ! function called in inferences_init 
   PUBLIC inf_dealloc        ! function called in inferences_final
   PUBLIC inferences_init    ! routine called in nemogcm.F90
   PUBLIC inferences         ! routine called in stpmlf.F90
   PUBLIC inferences_final   ! routine called in nemogcm.F90

   INTEGER, PARAMETER ::   jps_t = 1    ! sea temperature
   INTEGER, PARAMETER ::   jps_s = 2    ! sea salinity
   INTEGER, PARAMETER ::   jps_q  = 3   ! surface heat flux
   INTEGER, PARAMETER ::   jps_taux = 4 ! wind stress-x
   INTEGER, PARAMETER ::   jps_tauy = 5 ! wind stress-y
   INTEGER, PARAMETER ::   jps_stx = 6  ! Stokes Drift-x
   INTEGER, PARAMETER ::   jps_sty = 7  ! Stokes Drift-y
   INTEGER, PARAMETER ::   jps_inf = 7  ! total number of sendings for inferences

   INTEGER, PARAMETER ::   jpr_dTdt = 1   ! dT/dt profile
   INTEGER, PARAMETER ::   jpr_dSdt = 2   ! dS/dt profile
   INTEGER, PARAMETER ::   jpr_inf = 2   ! total number of inference receptions

   INTEGER, PARAMETER ::   jpinf = MAX(jps_inf,jpr_inf) ! Maximum number of exchanges

   TYPE( DYNARR ), SAVE, DIMENSION(jpinf) ::  infsnd, infrcv  ! sent/received inferences

   !
   !!-------------------------------------------------------------------------
   !!                    Namelist for the Inference Models
   !!-------------------------------------------------------------------------
   !                           !!** naminf namelist **
   !TYPE ::   FLD_INF              !: Field informations ...  
   !   CHARACTER(len = 32) ::         ! 
   !END TYPE FLD_INF
   !
   LOGICAL , PUBLIC ::   ln_inf    !: activate module for inference models
   
   !!-------------------------------------------------------------------------

CONTAINS

   INTEGER FUNCTION inf_alloc()
      !!----------------------------------------------------------------------
      !!             ***  FUNCTION inf_alloc  ***
      !!----------------------------------------------------------------------
      INTEGER :: ierr
      INTEGER :: jn
      !!----------------------------------------------------------------------
      ierr = 0
      !
      DO jn = 1, jpinf
         IF( srcv(ntypinf,jn)%laction ) ALLOCATE( infrcv(jn)%z3(jpi,jpj,srcv(ntypinf,jn)%nlvl), STAT=ierr )
         IF( ssnd(ntypinf,jn)%laction ) ALLOCATE( infsnd(jn)%z3(jpi,jpj,ssnd(ntypinf,jn)%nlvl), STAT=ierr )
         inf_alloc = MAX(ierr,0)
      END DO
      !
   END FUNCTION inf_alloc

   
   INTEGER FUNCTION inf_dealloc()
      !!----------------------------------------------------------------------
      !!             ***  FUNCTION inf_dealloc  ***
      !!----------------------------------------------------------------------
      INTEGER :: ierr
      INTEGER :: jn
      !!----------------------------------------------------------------------
      ierr = 0
      !
      DO jn = 1, jpinf
         IF( srcv(ntypinf,jn)%laction ) DEALLOCATE( infrcv(jn)%z3, STAT=ierr )
         IF( ssnd(ntypinf,jn)%laction ) DEALLOCATE( infsnd(jn)%z3, STAT=ierr )
         inf_dealloc = MAX(ierr,0)
      END DO
      !
   END FUNCTION inf_dealloc


   SUBROUTINE inferences_init 
      !!----------------------------------------------------------------------
      !!             ***  ROUTINE inferences_init  ***
      !!
      !! ** Purpose :   Initialisation of the models that rely on external inferences
      !!
      !! ** Method  :   * Read naminf namelist
      !!                * create data for models
      !!----------------------------------------------------------------------
      !
      INTEGER ::   ios   ! Local Integer
      !!
      LOGICAL ::  ln_inf
      !!----------------------------------------------------------------------
      !
      ! ================================ !
      !      Namelist informations       !
      ! ================================ !
      !
      ln_inf = .TRUE.
      !
      IF( lwp ) THEN                        ! control print
         WRITE(numout,*)
         WRITE(numout,*)'inferences_init : Setting inferences models'
         WRITE(numout,*)'~~~~~~~~~~~~~~~'
      END IF
      !
      IF( ln_inf .AND. .NOT. lk_oasis )   CALL ctl_stop( 'inferences_init : External inferences coupled via OASIS, but key_oasis3 disabled' )
      !
      !
      ! ======================================== !
      !     Define exchange needs for Models     !
      ! ======================================== !
      !
      ! default definitions of ssnd snd srcv
      srcv(ntypinf,:)%laction = .FALSE.  ;  srcv(ntypinf,:)%clgrid = 'T'  ;  srcv(ntypinf,:)%nsgn = 1.
      srcv(ntypinf,:)%nct = 1  ;  srcv(ntypinf,:)%nlvl = 1
      !
      ssnd(ntypinf,:)%laction = .FALSE.  ;  ssnd(ntypinf,:)%clgrid = 'T'  ;  ssnd(ntypinf,:)%nsgn = 1.
      ssnd(ntypinf,:)%nct = 1  ;  ssnd(ntypinf,:)%nlvl = 1
      
      IF( ln_inf ) THEN
      
         ! -------------------------------- !
         !      Kenigson et al. (2022)      !
         ! -------------------------------- !

         ! sending of sea temperature
         ssnd(ntypinf,jps_t)%clname = 'E_OUT_0'
         ssnd(ntypinf,jps_t)%laction = .TRUE.
         ssnd(ntypinf,jps_t)%nlvl = 32

         ! sending of sea salinity
         ssnd(ntypinf,jps_s)%clname = 'E_OUT_1'
         ssnd(ntypinf,jps_s)%laction = .TRUE.
         ssnd(ntypinf,jps_s)%nlvl = 32

         ! sending of Stokes drift-x
         ssnd(ntypinf,jps_stx)%clname = 'E_OUT_2'
         ssnd(ntypinf,jps_stx)%laction = .TRUE.
         ssnd(ntypinf,jps_stx)%nlvl = 32

         ! sending of Stokes drift-y
         ssnd(ntypinf,jps_sty)%clname = 'E_OUT_3'
         ssnd(ntypinf,jps_sty)%laction = .TRUE.
         ssnd(ntypinf,jps_sty)%nlvl = 32

         ! sending of surface heat flux
         ssnd(ntypinf,jps_q)%clname = 'E_OUT_4'
         ssnd(ntypinf,jps_q)%laction = .TRUE.

         ! sending of wind stress-x
         ssnd(ntypinf,jps_taux)%clname = 'E_OUT_5'
         ssnd(ntypinf,jps_taux)%laction = .TRUE.

         ! sending of wind stress-y
         ssnd(ntypinf,jps_tauy)%clname = 'E_OUT_6'
         ssnd(ntypinf,jps_tauy)%laction = .TRUE.

         ! reception of temperature mixing
         srcv(ntypinf,jpr_dTdt)%clname = 'E_IN_0'
         srcv(ntypinf,jpr_dTdt)%laction = .TRUE.
         srcv(ntypinf,jpr_dTdt)%nlvl = 32

         ! reception of salinity mixing
         srcv(ntypinf,jpr_dSdt)%clname = 'E_IN_1'
         srcv(ntypinf,jpr_dSdt)%laction = .TRUE.
         srcv(ntypinf,jpr_dSdt)%nlvl = 32
         ! ------------------------------ !
      END IF
      ! 
      ! ================================= !
      !   Define variables for coupling
      ! ================================= !
      CALL cpl_var(jpinf, jpinf, 1, ntypinf)
      !
      IF( inf_alloc() /= 0 )     CALL ctl_stop( 'STOP', 'inf_alloc : unable to allocate arrays' )
      IF( inffld_alloc() /= 0 )  CALL ctl_stop( 'STOP', 'inffld_alloc : unable to allocate arrays' ) 
      !
   END SUBROUTINE inferences_init


   SUBROUTINE inferences( kt, Kbb, Kmm, Kaa )
      !!----------------------------------------------------------------------
      !!             ***  ROUTINE inferences  ***
      !!
      !! ** Purpose :   update the ocean data with the ML based models
      !!
      !! ** Method  :   *  
      !!                * 
      !!----------------------------------------------------------------------
      INTEGER, INTENT(in) ::   kt            ! ocean time step
      INTEGER, INTENT(in) ::   Kbb, Kmm, Kaa ! ocean time level indices
      !
      INTEGER :: isec, info, jn                       ! local integer
      REAL(wp), DIMENSION(jpi,jpj,jpk)   ::  zdata    ! sending buffer
      !!----------------------------------------------------------------------
      !
      IF( ln_timing )   CALL timing_start('inferences')
      !
      isec = ( kt - nit000 ) * NINT( rn_Dt )       ! Date of exchange 
      info = OASIS_idle
      !
      ! ------  Prepare data to send ------
      !
      ! sea Temperature
      infsnd(jps_t)%z3(:,:,1:ssnd(ntypinf,jps_t)%nlvl) = ts(:,:,1:ssnd(ntypinf,jps_t)%nlvl,jp_tem,Kmm)
      !
      ! sea Salinity
      infsnd(jps_s)%z3(:,:,1:ssnd(ntypinf,jps_s)%nlvl) = ts(:,:,1:ssnd(ntypinf,jps_s)%nlvl,jp_sal,Kmm)
      !
      ! surface heat flux
      infsnd(jps_q)%z3(:,:,ssnd(ntypinf,jps_q)%nlvl) = qsr(:,:) + qns(:,:)
      !
      ! wind stress
      infsnd(jps_taux)%z3(:,:,ssnd(ntypinf,jps_taux)%nlvl) = utau(:,:)
      infsnd(jps_tauy)%z3(:,:,ssnd(ntypinf,jps_tauy)%nlvl) = vtau(:,:)
      !
      ! Stokes Drift
      infsnd(jps_stx)%z3(:,:,1:ssnd(ntypinf,jps_stx)%nlvl) = -1.0
      infsnd(jps_sty)%z3(:,:,1:ssnd(ntypinf,jps_sty)%nlvl) = -1.0
      CALL iom_put( "ustokes" , infsnd(jps_stx)%z3)
      CALL iom_put( "vstokes" , infsnd(jps_sty)%z3)
      !
      ! ========================
      !   Proceed all sendings
      ! ========================
      !
      DO jn = 1, jpinf
         IF ( ssnd(ntypinf,jn)%laction ) THEN
            CALL cpl_snd( jn, isec, ntypinf, infsnd(jn)%z3, info)
         ENDIF
      END DO
      !
      ! .... some external operations ....
      !
      ! ==========================
      !   Proceed all receptions
      ! ==========================
      !
      DO jn = 1, jpinf
         IF( srcv(ntypinf,jn)%laction ) THEN
            CALL cpl_rcv( jn, isec, ntypinf, infrcv(jn)%z3, info)
         ENDIF
      END DO
      !
      ! ------ Distribute receptions  ------
      !
      ! Temperature and salinity mixing
      dTdt(:,:,1:srcv(ntypinf,jpr_dTdt)%nlvl) = infrcv(jpr_dTdt)%z3(:,:,1:srcv(ntypinf,jpr_dTdt)%nlvl)
      dSdt(:,:,1:srcv(ntypinf,jpr_dSdt)%nlvl) = infrcv(jpr_dSdt)%z3(:,:,1:srcv(ntypinf,jpr_dSdt)%nlvl)
      CALL iom_put( 'inf_dTdt', dTdt(:,:,:) )
      CALL iom_put( 'inf_dSdt', dSdt(:,:,:) )
      !
      IF( ln_timing )   CALL timing_stop('inference')
      !
   END SUBROUTINE inferences


   SUBROUTINE inferences_final
      !!----------------------------------------------------------------------
      !!             ***  ROUTINE inferences_final  ***
      !!
      !! ** Purpose :   Free memory used for inferences modules
      !!
      !! ** Method  :   * Deallocate arrays
      !!----------------------------------------------------------------------
      !
      IF( inf_dealloc() /= 0 )     CALL ctl_stop( 'STOP', 'inf_dealloc : unable to free memory' )
      IF( inffld_dealloc() /= 0 )  CALL ctl_stop( 'STOP', 'inffld_dealloc : unable to free memory' )      
      !
   END SUBROUTINE inferences_final 
   !!=======================================================================
END MODULE infmod

!################################################################################
!This file is part of Incompact3d.
!
!Incompact3d
!Copyright (c) 2012 Eric Lamballais and Sylvain Laizet
!eric.lamballais@univ-poitiers.fr / sylvain.laizet@gmail.com
!
!    Incompact3d is free software: you can redistribute it and/or modify
!    it under the terms of the GNU General Public License as published by
!    the Free Software Foundation.
!
!    Incompact3d is distributed in the hope that it will be useful,
!    but WITHOUT ANY WARRANTY; without even the implied warranty of
!    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
!    GNU General Public License for more details.
!
!    You should have received a copy of the GNU General Public License
!    along with the code.  If not, see <http://www.gnu.org/licenses/>.
!-------------------------------------------------------------------------------
!-------------------------------------------------------------------------------
!    We kindly request that you cite Incompact3d in your publications and 
!    presentations. The following citations are suggested:
!
!    1-Laizet S. & Lamballais E., 2009, High-order compact schemes for 
!    incompressible flows: a simple and efficient method with the quasi-spectral 
!    accuracy, J. Comp. Phys.,  vol 228 (15), pp 5989-6015
!
!    2-Laizet S. & Li N., 2011, Incompact3d: a powerful tool to tackle turbulence 
!    problems with up to 0(10^5) computational cores, Int. J. of Numerical 
!    Methods in Fluids, vol 67 (11), pp 1735-1757
!################################################################################

!********************************************************************
!
! 
!********************************************************************
subroutine convdiff(ux1,uy1,uz1,rho1,mu1,ta1,tb1,tc1,td1,te1,tf1,tg1,th1,ti1,di1,&
     ux2,uy2,uz2,rho2,mu2,ta2,tb2,tc2,td2,te2,tf2,tg2,th2,ti2,tj2,di2,&
     ux3,uy3,uz3,rho3,mu3,divu3,ta3,tb3,tc3,td3,te3,tf3,tg3,th3,ti3,di3)

  USE param
  USE variables
  USE decomp_2d

  USE MPI

  implicit none

  real(mytype),dimension(xsize(1),xsize(2),xsize(3)) :: ux1,uy1,uz1
  real(mytype),dimension(xsize(1),xsize(2),xsize(3)) :: ta1,tb1,tc1,td1,te1,tf1,tg1,th1,ti1,di1
  real(mytype),dimension(ysize(1),ysize(2),ysize(3)) :: ux2,uy2,uz2 
  real(mytype),dimension(ysize(1),ysize(2),ysize(3)) :: ta2,tb2,tc2,td2,te2,tf2,tg2,th2,ti2,tj2,di2
  real(mytype),dimension(zsize(1),zsize(2),zsize(3)) :: ux3,uy3,uz3
  real(mytype),dimension(zsize(1),zsize(2),zsize(3)) :: ta3,tb3,tc3,td3,te3,tf3,tg3,th3,ti3,di3

  real(mytype),dimension(xsize(1),xsize(2),xsize(3)) :: rho1
  real(mytype),dimension(ysize(1),ysize(2),ysize(3)) :: rho2
  real(mytype),dimension(zsize(1),zsize(2),zsize(3)) :: rho3

  real(mytype),dimension(xsize(1),xsize(2),xsize(3)) :: divu1
  real(mytype),dimension(ysize(1),ysize(2),ysize(3)) :: divu2
  real(mytype),dimension(zsize(1),zsize(2),zsize(3)) :: divu3

  real(mytype),dimension(xsize(1),xsize(2),xsize(3)) :: clx1, cly1, clz1
  real(mytype),dimension(ysize(1),ysize(2),ysize(3)) :: clx2, cly2, clz2
  real(mytype),dimension(zsize(1),zsize(2),zsize(3)) :: clx3, cly3, clz3
  
  real(mytype),dimension(xsize(1),xsize(2),xsize(3)) :: mu1
  real(mytype),dimension(ysize(1),ysize(2),ysize(3)) :: mu2
  real(mytype),dimension(zsize(1),zsize(2),zsize(3)) :: mu3

  integer :: ijk,nvect1,nvect2,nvect3,i,j,k
  real(mytype) :: x,y,z

  real(mytype), parameter :: ONETHIRD = 1._mytype / 3._mytype

  logical :: entrain_y, entrain_z

  entrain_y = .FALSE.
  entrain_z = .FALSE.
  if (itype.eq.5) then
     if (ncly.eq.2) then
        entrain_y = .TRUE.
     endif
     if (nclz.eq.2) then
        entrain_z = .TRUE.
     endif
  endif

  nvect1=xsize(1)*xsize(2)*xsize(3)
  nvect2=ysize(1)*ysize(2)*ysize(3)
  nvect3=zsize(1)*zsize(2)*zsize(3)

  if (iskew==0) then !UROTU!
    !WORK X-PENCILS
    call derx (ta1,uy1,di1,sx,ffxp,fsxp,fwxp,xsize(1),xsize(2),xsize(3),1)
    call derx (tb1,uz1,di1,sx,ffxp,fsxp,fwxp,xsize(1),xsize(2),xsize(3),1)
    call transpose_x_to_y(ux1,ux2)
    call transpose_x_to_y(uy1,uy2)
    call transpose_x_to_y(uz1,uz2)
    call transpose_x_to_y(ta1,ta2)
    call transpose_x_to_y(tb1,tb2)
    
    !WORK Y-PENCILS
    call dery (tc2,ux2,di2,sy,ffyp,fsyp,fwyp,ppy,ysize(1),ysize(2),ysize(3),1) 
    call dery (td2,uz2,di2,sy,ffyp,fsyp,fwyp,ppy,ysize(1),ysize(2),ysize(3),1) 
    call transpose_y_to_z(ux2,ux3)
    call transpose_y_to_z(uy2,uy3)
    call transpose_y_to_z(uz2,uz3)
    call transpose_y_to_z(ta2,ta3)
    call transpose_y_to_z(tb2,tb3)
    call transpose_y_to_z(tc2,tc3)
    call transpose_y_to_z(td2,td3)
    
    !WORK Z-PENCILS
    call derz (te3,ux3,di3,sz,ffzp,fszp,fwzp,zsize(1),zsize(2),zsize(3),1)
    call derz (tf3,uy3,di3,sz,ffzp,fszp,fwzp,zsize(1),zsize(2),zsize(3),1)
    do ijk=1,nvect3
      ta3(ijk,1,1)=uz3(ijk,1,1)*(te3(ijk,1,1)-tb3(ijk,1,1))-&
           uy3(ijk,1,1)*(ta3(ijk,1,1)-tc3(ijk,1,1))
      tb3(ijk,1,1)=ux3(ijk,1,1)*(ta3(ijk,1,1)-tc3(ijk,1,1))-&
           uz3(ijk,1,1)*(td3(ijk,1,1)-tf3(ijk,1,1))
      tc3(ijk,1,1)=uy3(ijk,1,1)*(td3(ijk,1,1)-tf3(ijk,1,1))-&
           ux3(ijk,1,1)*(te3(ijk,1,1)-tb3(ijk,1,1))
    enddo
  else !SKEW!
    !WORK X-PENCILS
    td1(:,:,:) = rho1(:,:,:) * ux1(:,:,:) * ux1(:,:,:)
    te1(:,:,:) = rho1(:,:,:) * uy1(:,:,:) * ux1(:,:,:)
    tf1(:,:,:) = rho1(:,:,:) * uz1(:,:,:) * ux1(:,:,:)

    call derx (tg1,td1,di1,sx,ffxp,fsxp,fwxp,xsize(1),xsize(2),xsize(3),1)
    call derx (th1,te1,di1,sx,ffx,fsx,fwx,xsize(1),xsize(2),xsize(3),0)
    call derx (ti1,tf1,di1,sx,ffx,fsx,fwx,xsize(1),xsize(2),xsize(3),0)
    call derx (td1,ux1,di1,sx,ffx,fsx,fwx,xsize(1),xsize(2),xsize(3),0)
    call derx (te1,uy1,di1,sx,ffxp,fsxp,fwxp,xsize(1),xsize(2),xsize(3),1)
    call derx (tf1,uz1,di1,sx,ffxp,fsxp,fwxp,xsize(1),xsize(2),xsize(3),1)

    ta1(:,:,:) = tg1(:,:,:) + rho1(:,:,:) * ux1(:,:,:) * td1(:,:,:)
    tb1(:,:,:) = th1(:,:,:) + rho1(:,:,:) * ux1(:,:,:) * te1(:,:,:)
    tc1(:,:,:) = ti1(:,:,:) + rho1(:,:,:) * ux1(:,:,:) * tf1(:,:,:)

    if ((iskew.eq.1).and.(ilmn.ne.0)) then
      ! Quasi-skew symmetric terms
      call derx(tg1,rho1,di1,sx,ffxp,fsxp,fwxp,xsize(1),xsize(2),xsize(3),1)
      ta1(:,:,:) = ta1(:,:,:) + ux1(:,:,:) * ux1(:,:,:) * tg1(:,:,:)
      tb1(:,:,:) = tb1(:,:,:) + uy1(:,:,:) * ux1(:,:,:) * tg1(:,:,:)
      tc1(:,:,:) = tc1(:,:,:) + uz1(:,:,:) * ux1(:,:,:) * tg1(:,:,:)
    endif

    call transpose_x_to_y(ux1,ux2)
    call transpose_x_to_y(uy1,uy2)
    call transpose_x_to_y(uz1,uz2)
    call transpose_x_to_y(ta1,ta2)
    call transpose_x_to_y(tb1,tb2)
    call transpose_x_to_y(tc1,tc2)

    call transpose_x_to_y(rho1,rho2)
    
    !WORK Y-PENCILS
    td2(:,:,:) = rho2(:,:,:) * ux2(:,:,:) * uy2(:,:,:)
    te2(:,:,:) = rho2(:,:,:) * uy2(:,:,:) * uy2(:,:,:)
    tf2(:,:,:) = rho2(:,:,:) * uz2(:,:,:) * uy2(:,:,:)

    call dery (tg2,td2,di2,sy,ffy,fsy,fwy,ppy,ysize(1),ysize(2),ysize(3),0) 
    call dery (th2,te2,di2,sy,ffyp,fsyp,fwyp,ppy,ysize(1),ysize(2),ysize(3),1)
    call dery (ti2,tf2,di2,sy,ffy,fsy,fwy,ppy,ysize(1),ysize(2),ysize(3),0) 
    call dery (td2,ux2,di2,sy,ffyp,fsyp,fwyp,ppy,ysize(1),ysize(2),ysize(3),1) 
    call dery (te2,uy2,di2,sy,ffy,fsy,fwy,ppy,ysize(1),ysize(2),ysize(3),0)
    call dery (tf2,uz2,di2,sy,ffyp,fsyp,fwyp,ppy,ysize(1),ysize(2),ysize(3),1)

    ta2(:,:,:) = ta2(:,:,:) + tg2(:,:,:) + rho2(:,:,:) * uy2(:,:,:) * td2(:,:,:)
    tb2(:,:,:) = tb2(:,:,:) + th2(:,:,:) + rho2(:,:,:) * uy2(:,:,:) * te2(:,:,:)
    tc2(:,:,:) = tc2(:,:,:) + ti2(:,:,:) + rho2(:,:,:) * uy2(:,:,:) * tf2(:,:,:)

    if ((iskew.eq.1).and.(ilmn.ne.0)) then
      ! Quasi-skew symmetric terms
      call dery(th2,rho2,di2,sy,ffyp,fsyp,fwyp,ppy,ysize(1),ysize(2),ysize(3),1)
      ta2(:,:,:) = ta2(:,:,:) + ux2(:,:,:) * uy2(:,:,:) * th2(:,:,:)
      tb2(:,:,:) = tb2(:,:,:) + uy2(:,:,:) * uy2(:,:,:) * th2(:,:,:)
      tc2(:,:,:) = tc2(:,:,:) + uz2(:,:,:) * uy2(:,:,:) * th2(:,:,:)
    endif

    call transpose_y_to_z(ux2,ux3)
    call transpose_y_to_z(uy2,uy3)
    call transpose_y_to_z(uz2,uz3)
    call transpose_y_to_z(ta2,ta3)
    call transpose_y_to_z(tb2,tb3)
    call transpose_y_to_z(tc2,tc3)

    call transpose_y_to_z(rho2,rho3)
    
    !WORK Z-PENCILS
    td3(:,:,:) = rho3(:,:,:) * ux3(:,:,:) * uz3(:,:,:)
    te3(:,:,:) = rho3(:,:,:) * uy3(:,:,:) * uz3(:,:,:)
    tf3(:,:,:) = rho3(:,:,:) * uz3(:,:,:) * uz3(:,:,:)

    call derz (tg3,td3,di3,sz,ffz,fsz,fwz,zsize(1),zsize(2),zsize(3),0)
    call derz (th3,te3,di3,sz,ffz,fsz,fwz,zsize(1),zsize(2),zsize(3),0)
    call derz (ti3,tf3,di3,sz,ffzp,fszp,fwzp,zsize(1),zsize(2),zsize(3),1)
    call derz (td3,ux3,di3,sz,ffzp,fszp,fwzp,zsize(1),zsize(2),zsize(3),1)
    call derz (te3,uy3,di3,sz,ffzp,fszp,fwzp,zsize(1),zsize(2),zsize(3),1)
    call derz (tf3,uz3,di3,sz,ffz,fsz,fwz,zsize(1),zsize(2),zsize(3),0)

    ta3(:,:,:) = ta3(:,:,:) + tg3(:,:,:) + rho3(:,:,:) * uz3(:,:,:) * td3(:,:,:)
    tb3(:,:,:) = tb3(:,:,:) + th3(:,:,:) + rho3(:,:,:) * uz3(:,:,:) * te3(:,:,:)
    tc3(:,:,:) = tc3(:,:,:) + ti3(:,:,:) + rho3(:,:,:) * uz3(:,:,:) * tf3(:,:,:)

    if ((iskew.eq.1).and.(ilmn.ne.0)) then
      ! Quasi-skew symmetric terms (Note here also include contribution from div(u))
      call derz(ti3,rho3,di3,sz,ffzp,fszp,fwzp,zsize(1),zsize(2),zsize(3),1)
      ta3(:,:,:) = ta3(:,:,:) + ux3(:,:,:) &
           * (uz3(:,:,:) * ti3(:,:,:) + rho3(:,:,:) * divu3(:,:,:))
      tb3(:,:,:) = tb3(:,:,:) + uy3(:,:,:) &
           * (uz3(:,:,:) * ti3(:,:,:) + rho3(:,:,:) * divu3(:,:,:))
      tc3(:,:,:) = tc3(:,:,:) + uz3(:,:,:) &
           * (uz3(:,:,:) * ti3(:,:,:) + rho3(:,:,:) * divu3(:,:,:))
    endif

    !! Need to multiply by 1/2
    ta3(:,:,:) = 0.5_mytype * ta3(:,:,:)
    tb3(:,:,:) = 0.5_mytype * tb3(:,:,:)
    tc3(:,:,:) = 0.5_mytype * tc3(:,:,:)
  endif
  !ALL THE CONVECTIVE TERMS ARE IN TA3, TB3 and TC3

  tg3(:,:,:) = ta3(:,:,:)
  th3(:,:,:) = tb3(:,:,:)
  ti3(:,:,:) = tc3(:,:,:)

  !DIFFUSIVE TERMS IN Z
  call derzz (ta3,ux3,di3,sz,sfzp,sszp,swzp,zsize(1),zsize(2),zsize(3),1)
  call derzz (tb3,uy3,di3,sz,sfzp,sszp,swzp,zsize(1),zsize(2),zsize(3),1)
  call derzz (tc3,uz3,di3,sz,sfz ,ssz ,swz ,zsize(1),zsize(2),zsize(3),0)

  ta3(:,:,:) = mu3(:,:,:) * ta3(:,:,:)
  tb3(:,:,:) = mu3(:,:,:) * tb3(:,:,:)
  tc3(:,:,:) = mu3(:,:,:) * tc3(:,:,:)

  if (ilmn.ne.0) then
    !! Compute bulk shear contribution
    ! tg3, th3, ti3 available as work vectors
    ! TODO need to check ffzp, and whether last terms should be 1 or 0
    call derz(tf3, divu3, di3, sz, ffz, fsz, fwz, zsize(1), zsize(2), zsize(3), 0)
    tc3(:,:,:) = tc3(:,:,:) - 2._mytype * ONETHIRD * mu3(:,:,:) * tf3(:,:,:)
  endif

  !! XXX Transpose advection terms to make room for 2nd non-conservative diffusion
  !      term
  call transpose_z_to_y(tg3,tg2)
  call transpose_z_to_y(th3,th2)
  call transpose_z_to_y(ti3,ti2)

  if (iprops.ne.0) then
    !! Fluid properties are variable
    
    call derz(td3, ux3, di3, sz, ffzp, fszp, fwzp, zsize(1), zsize(2), zsize(3), 1)
    call derz(te3, uy3, di3, sz, ffzp, fszp, fwzp, zsize(1), zsize(2), zsize(3), 1)
    call derz(tf3, uz3, di3, sz, ffz, fsz, fwz, zsize(1), zsize(2), zsize(3), 0)
    call derz(ti3, mu3, di3, sz, ffzp, fszp, fwzp, zsize(1), zsize(2), zsize(3), 1)
    
    ta3(:,:,:) = ta3(:,:,:) + ti3(:,:,:) * td3(:,:,:)
    tb3(:,:,:) = tb3(:,:,:) + ti3(:,:,:) * te3(:,:,:)
    tc3(:,:,:) = tc3(:,:,:) + ti3(:,:,:) * tf3(:,:,:) &
         - ti3(:,:,:) * 2._mytype * ONETHIRD * divu3(:,:,:)
  endif

  clx3(:,:,:) = 0._mytype
  cly3(:,:,:) = 0._mytype
  clz3(:,:,:) = 0._mytype
  IF (entrain_y.EQV..TRUE.) THEN
    !! Apply y-normal BCs (in Z pencil)
    CALL entrainment_bcy(ux3, uy3, uz3, clx3, cly3, clz3)
  ENDIF

  call transpose_z_to_y(ta3,ta2)
  call transpose_z_to_y(tb3,tb2)
  call transpose_z_to_y(tc3,tc2)

  call transpose_z_to_y(divu3, divu2)
  if (iprops.eq.0) then
    mu2(:,:,:) = 1._mytype
  endif
  
  !WORK Y-PENCILS

  IF ((entrain_y.EQV..TRUE.).OR.(entrain_z.EQV..TRUE.)) THEN
    CALL transpose_z_to_y(clx3, clx2)
    CALL transpose_z_to_y(cly3, cly2)
    CALL transpose_z_to_y(clz3, clz2)
  ENDIF

  !DIFFUSIVE TERMS IN Y
  !-->for ux
  if (istret.ne.0) then 
    call deryy (td2,ux2,di2,sy,sfyp,ssyp,swyp,ysize(1),ysize(2),ysize(3),1)
    call dery (te2,ux2,di2,sy,ffyp,fsyp,fwyp,ppy,ysize(1),ysize(2),ysize(3),1)
    do k=1,ysize(3)
      do j=1,ysize(2)
        do i=1,ysize(1)
          td2(i,j,k)=td2(i,j,k)*pp2y(j)-pp4y(j)*te2(i,j,k)
        enddo
      enddo
    enddo
  else
    call deryy (td2,ux2,di2,sy,sfyp,ssyp,swyp,ysize(1),ysize(2),ysize(3),1) 
  endif

  !-->for uy
  if (istret.ne.0) then 
    call deryy (te2,uy2,di2,sy,sfy,ssy,swy,ysize(1),ysize(2),ysize(3),0)
    call dery (tf2,uy2,di2,sy,ffy,fsy,fwy,ppy,ysize(1),ysize(2),ysize(3),0)
    do k=1,ysize(3)
      do j=1,ysize(2)
        do i=1,ysize(1)
          te2(i,j,k)=te2(i,j,k)*pp2y(j)-pp4y(j)*tf2(i,j,k)
        enddo
      enddo
    enddo
  else
    call deryy (te2,uy2,di2,sy,sfy,ssy,swy,ysize(1),ysize(2),ysize(3),0) 
  endif
  !-->for uz
  if (istret.ne.0) then 
    call deryy (tf2,uz2,di2,sy,sfyp,ssyp,swyp,ysize(1),ysize(2),ysize(3),1)
    call dery (tj2,uz2,di2,sy,ffyp,fsyp,fwyp,ppy,ysize(1),ysize(2),ysize(3),1)
    do k=1,ysize(3)
      do j=1,ysize(2)
        do i=1,ysize(1)
          tf2(i,j,k)=tf2(i,j,k)*pp2y(j)-pp4y(j)*tj2(i,j,k)
        enddo
      enddo
    enddo
  else
    call deryy (tf2,uz2,di2,sy,sfyp,ssyp,swyp,ysize(1),ysize(2),ysize(3),1) 
  endif

  ta2(:,:,:) = ta2(:,:,:) + mu2(:,:,:) * td2(:,:,:)
  tb2(:,:,:) = tb2(:,:,:) + mu2(:,:,:) * te2(:,:,:)
  tc2(:,:,:) = tc2(:,:,:) + mu2(:,:,:) * tf2(:,:,:)

  if (ilmn.ne.0) then
    !! Compute bulk shear contribution
    ! td2, te2, tf2 avaiable as work vectors
    call dery(te2, divu2, di2, sy, ffy, fsy, fwy, ppy, ysize(1), ysize(2), ysize(3), 0)
    tb2(:,:,:) = tb2(:,:,:) - 2._mytype * ONETHIRD * mu2(:,:,:) * te2(:,:,:)
  endif

  IF (entrain_z.EQV..TRUE.) THEN
    !! Apply Z-normal BCs
    CALL entrainment_bcz(ux2, uy2, uz2, clx2, cly2, clz2)
  ENDIF
  
  !! XXX First move advection terms to make room to work
  call transpose_y_to_x(tg2,tg1)
  call transpose_y_to_x(th2,th1)
  call transpose_y_to_x(ti2,ti1) !conv

  if (iprops.ne.0) then
    !! Compute non-conservative part of viscous stress tensor
    call dery (td2,ux2,di2,sy,ffyp,fsyp,fwyp,ppy,ysize(1),ysize(2),ysize(3),1) 
    call dery (te2,uy2,di2,sy,ffy,fsy,fwy,ppy,ysize(1),ysize(2),ysize(3),0)
    call dery (tf2,uz2,di2,sy,ffyp,fsyp,fwyp,ppy,ysize(1),ysize(2),ysize(3),1)
    call dery (th2,mu2,di2,sy,ffyp,fsyp,fwyp,ppy,ysize(1),ysize(2),ysize(3),1)
    
    ta2(:,:,:) = ta2(:,:,:) + th2(:,:,:) * td2(:,:,:)
    tb2(:,:,:) = tb2(:,:,:) + th2(:,:,:) * te2(:,:,:) &
         - th2(:,:,:) * 2._mytype * ONETHIRD * divu2(:,:,:)
    tc2(:,:,:) = tc2(:,:,:) + th2(:,:,:) * tf2(:,:,:)
  endif

  !WORK X-PENCILS
  call transpose_y_to_x(ta2,ta1)
  call transpose_y_to_x(tb2,tb1)
  call transpose_y_to_x(tc2,tc1) !diff

  call transpose_y_to_x(divu2, divu1)
  if (iprops.eq.0) then
    mu1(:,:,:) = 1._mytype
  endif

  !WORK X-PENCILS

  IF ((entrain_y.EQV..TRUE.).OR.(entrain_z.EQV..TRUE.)) THEN
    CALL transpose_y_to_x(clx2, clx1)
    CALL transpose_y_to_x(cly2, cly1)
    CALL transpose_y_to_x(clz2, clz1)
  ENDIF

  !DIFFUSIVE TERMS IN X
  call derxx (td1,ux1,di1,sx,sfx ,ssx ,swx ,xsize(1),xsize(2),xsize(3),0)
  call derxx (te1,uy1,di1,sx,sfxp,ssxp,swxp,xsize(1),xsize(2),xsize(3),1)
  call derxx (tf1,uz1,di1,sx,sfxp,ssxp,swxp,xsize(1),xsize(2),xsize(3),1)

  ta1(:,:,:) = ta1(:,:,:) + mu1(:,:,:) * td1(:,:,:)
  tb1(:,:,:) = tb1(:,:,:) + mu1(:,:,:) * te1(:,:,:)
  tc1(:,:,:) = tc1(:,:,:) + mu1(:,:,:) * tf1(:,:,:)

  if (ilmn.ne.0) then
    !! Compute bulk shear contribution
    ! td1, te1, tf1 available as work vectors
    ! TODO need to check ffzp, and whether last terms should be 1 or 0
    call derx(td1, divu1, di1, sx, ffx, fsx, fwx, xsize(1), xsize(2), xsize(3), 0)
    ta1(:,:,:) = ta1(:,:,:) - 2._mytype * ONETHIRD * mu1(:,:,:) * td1(:,:,:)
  endif

  !INTERMEDIATE SUM: DIFF TERMS + CONV TERMS
  ta1(:,:,:) = xnu * ta1(:,:,:) - tg1(:,:,:)
  tb1(:,:,:) = xnu * tb1(:,:,:) - th1(:,:,:)
  tc1(:,:,:) = xnu * tc1(:,:,:) - ti1(:,:,:)
  
  !! We now have room to do the non-conservative part of viscous stress tensor
  if (iprops.ne.0) then
    call derx (td1,ux1,di1,sx,ffx,fsx,fwx,xsize(1),xsize(2),xsize(3),0)
    call derx (te1,uy1,di1,sx,ffxp,fsxp,fwxp,xsize(1),xsize(2),xsize(3),1)
    call derx (tf1,uz1,di1,sx,ffxp,fsxp,fwxp,xsize(1),xsize(2),xsize(3),1)
    call derx (tg1,mu1,di1,sx,ffxp,fsxp,fwxp,xsize(1),xsize(2),xsize(3),1)
    
    ta1(:,:,:) = ta1(:,:,:) + xnu * (tg1(:,:,:) * td1(:,:,:) &
         - tg1(:,:,:) * 2._mytype * ONETHIRD * divu1(:,:,:))
    tb1(:,:,:) = tb1(:,:,:) + xnu * tg1(:,:,:) * te1(:,:,:)
    tc1(:,:,:) = tc1(:,:,:) + xnu * tg1(:,:,:) * tf1(:,:,:)
 endif

 if (ilmn.ne.0) then
    !! Compute cross-shear
    ! NB ta1,tb1,tc1 cannot be touched!
    ! NB u2,u3 have already been updated, no need to transpose velocities!
  
    ! X - accumulate d(v,w)dx terms
    call derx(te1, uy1, di1, sx, ffxp, fsxp, fwxp, xsize(1), xsize(2), xsize(3), 1)
    call derx(tf1, uz1, di1, sx, ffxp, fsxp, fwxp, xsize(1), xsize(2), xsize(3), 1)
  
    call transpose_x_to_y(te1, te2) ! te2 contains dvdx
    call transpose_x_to_y(tf1, tf2) ! tf2 contains dwdx
  
    ! Y - accumulate dwdy terms
    call dery(ti2, uz2, di2, sy, ffyp, fsyp, fwyp, ppy, ysize(1), ysize(2), ysize(3), 1)
  
    call transpose_y_to_z(tf2, tg3) ! tg3 contains dwdx
    call transpose_y_to_z(ti2, th3) ! th3 contains dwdy

    ! Z - accumulate ddz terms
    call derz(ta3, ux3, di3, sz, ffzp, fszp, fwzp, zsize(1), zsize(2), zsize(3), 1)
    call derz(tb3, uy3, di3, sz, ffzp, fszp, fwzp, zsize(1), zsize(2), zsize(3), 1)
    call derz(tc3, uz3, di3, sz, ffz, fsz, fwz, zsize(1), zsize(2), zsize(3), 0)

    ! Z - compute ddz(dwdx, dwdy, dwdz)
    call derz(td3, tg3, di3, sz, ffz, fsz, fwz, zsize(1), zsize(2), zsize(3), 0)
    call derz(te3, th3, di3, sz, ffz, fsz, fwz, zsize(1), zsize(2), zsize(3), 0)
    call derz(tf3, tc3, di3, sz, ffzp, fszp, fwzp, zsize(1), zsize(2), zsize(3), 1)

    td3(:,:,:) = mu3(:,:,:) * td3(:,:,:)
    te3(:,:,:) = mu3(:,:,:) * te3(:,:,:)
    tf3(:,:,:) = mu3(:,:,:) * tf3(:,:,:)
    
    if (iprops.ne.0) then
       !! Store dmudz in ti3
       call derz(ti3, mu3, di3, sz, ffzp, fszp, fwzp, zsize(1), zsize(2), zsize(3), 1)

       ! Add dmudz * \nabla w to cross-shear
       td3(:,:,:) = td3(:,:,:) + ti3(:,:,:) * tg3(:,:,:)
       te3(:,:,:) = te3(:,:,:) + ti3(:,:,:) * th3(:,:,:)
       tf3(:,:,:) = tf3(:,:,:) + ti3(:,:,:) * tc3(:,:,:)
    endif

    call transpose_z_to_y(td3, tg2) ! tg2 contains mu * d2wdzdx + dmudz * dwdx
    call transpose_z_to_y(te3, th2) ! th2 contains mu * d2wdzdy + dmudz * dwdy
    call transpose_z_to_y(tf3, ti2) ! ti2 contains mu * d2wdzdz + dmudz * dwdz

    call transpose_z_to_y(ta3, ta2) ! ta2 contains dudz
    call transpose_z_to_y(tb3, tb2) ! tb2 contains dvdz

    ! Y - compute ddy(dvdx, dvdy, dvdz)

    tj2(:,:,:) = te2(:,:,:) ! Store dvdx
  
    call dery(td2, te2, di2, sy, ffy, fsy, fwy, ppy, ysize(1), ysize(2), ysize(3), 0)
    call dery(tc2, uy2, di2, sy, ffy, fsy, fwy, ppy, ysize(1), ysize(2), ysize(3), 0)
    call dery(te2, tc2, di2, sy, ffyp, fsyp, fwyp, ppy, ysize(1), ysize(2), ysize(3), 1)
    call dery(tf2, tb2, di2, sy, ffy, fsy, fwy, ppy, ysize(1), ysize(2), ysize(3), 0)

    td2(:,:,:) = mu2(:,:,:) * td2(:,:,:)
    te2(:,:,:) = mu2(:,:,:) * te2(:,:,:)
    tf2(:,:,:) = mu2(:,:,:) * tf2(:,:,:)
  
    td2(:,:,:) = td2(:,:,:) + tg2(:,:,:) ! td2 contains mu * (d2vdydx + d2wdzdx) + dmudz * dwdx
    te2(:,:,:) = te2(:,:,:) + th2(:,:,:) ! te2 contains mu * (d2vdydy + d2wdzdy) + dmudz * dwdy
    tf2(:,:,:) = tf2(:,:,:) + ti2(:,:,:) ! tf2 contains mu * (d2vdydz + d2wdzdz) + dmudz * dwdz
  
    if (iprops.ne.0) then
       !! Store dmudy in th2
       call dery(th2, mu2, di2, sy, ffyp, fsyp, fwyp, ppy, ysize(1), ysize(2), ysize(3), 1)
     
       ! Add dmudy * \nabla v to cross-shear
       td2(:,:,:) = td2(:,:,:) + th2(:,:,:) * tj2(:,:,:)
       te2(:,:,:) = te2(:,:,:) + th2(:,:,:) * tc2(:,:,:)
       tf2(:,:,:) = tf2(:,:,:) + th2(:,:,:) * tb2(:,:,:)
    endif
  
    call transpose_y_to_x(td2, td1) ! td1 contains mu * (d2vdydx + d2wdzdx) + (dmudy * dvdx + dmudz * dwdx)
    call transpose_y_to_x(te2, te1) ! te1 contains mu * (d2vdydy + d2wdzdy) + (dmudy * dvdy + dmudz * dwdy)
    call transpose_y_to_x(tf2, tf1) ! tf1 contains mu * (d2vdydz + d2wdzdz) + (dmudy * dvdz + dmudz * dwdz)
  
    call dery(tc2, ux2, di2, sy, ffyp, fsyp, fwyp, ppy, ysize(1), ysize(2), ysize(3), 1)
    call transpose_y_to_x(tc2, th1) ! th1 contains dudy
    call transpose_y_to_x(ta2, ti1) ! ti1 contains dudz
  
    ! X - compute ddx(dudx, dudy, dudz)
  
    ! First make some room to work!
    ta1(:,:,:) = ta1(:,:,:) + xnu * td1(:,:,:)
    tb1(:,:,:) = tb1(:,:,:) + xnu * te1(:,:,:)
    tc1(:,:,:) = tc1(:,:,:) + xnu * tf1(:,:,:)
  
    call derx(tg1, ux1, di1, sx, ffx, fsx, fwx, xsize(1), xsize(2), xsize(3), 0)
  
    call derx(td1, tg1, di1, sx, ffxp, fsxp, fwxp, xsize(1), xsize(2), xsize(3), 1)
    call derx(te1, th1, di1, sx, ffx, fsx, fwx, xsize(1), xsize(2), xsize(3), 0)
    call derx(tf1, ti1, di1, sx, ffx, fsx, fwx, xsize(1), xsize(2), xsize(3), 0)
  
    !! Finish off adding cross-stresses to shear stress
    ta1(:,:,:) = ta1(:,:,:) + xnu * mu1(:,:,:) * td1(:,:,:)
    tb1(:,:,:) = tb1(:,:,:) + xnu * mu1(:,:,:) * te1(:,:,:)
    tc1(:,:,:) = tc1(:,:,:) + xnu * mu1(:,:,:) * tf1(:,:,:)
  
    if (iprops.ne.0) then
       !! Add dmudx * \nabla u to cross-shear
       call derx(td1, mu1, di1, sx, ffxp, fsxp, fwxp, xsize(1), xsize(2), xsize(3), 1)
       ta1(:,:,:) = ta1(:,:,:) + xnu * td1(:,:,:) * tg1(:,:,:)
       tb1(:,:,:) = tb1(:,:,:) + xnu * td1(:,:,:) * th1(:,:,:)
       tc1(:,:,:) = tc1(:,:,:) + xnu * td1(:,:,:) * ti1(:,:,:)
    endif
 endif
 
 ! CALL fringe_bcx(ta1, tb1, tc1, ux1, uy1, uz1, rho1)
 
 !! Setting entrainment boundary conditions
 IF (entrain_z.EQV..TRUE.) THEN
    CALL set_velocity_entrainment_z(clx1, cly1, clz1)
 ENDIF !! End Z BC
 
 IF (entrain_y.EQV..TRUE.) THEN
    CALL set_velocity_entrainment_y(clx1, cly1, clz1)
 ENDIF !! End Y BC
 
 ! !! MMS Source term
 ! call momentum_source_mms(ta1,tb1,tc1)

end subroutine convdiff


!************************************************************
!
!
!************************************************************
subroutine scalar(ux1,uy1,uz1,rho1,phi1,gamma1,phis1,phiss1,di1,ta1,tb1,tc1,td1,&
     uy2,uz2,rho2,phi2,gamma2,di2,ta2,tb2,tc2,td2,&
     uz3,rho3,phi3,gamma3,di3,ta3,tb3,tc3,epsi)

  USE param
  USE variables
  USE decomp_2d

  implicit none

  real(mytype),dimension(xsize(1),xsize(2),xsize(3)) :: ux1,uy1,uz1,rho1,phi1,gamma1,phis1,&
       phiss1,di1,ta1,tb1,tc1,td1,epsi
  real(mytype),dimension(ysize(1),ysize(2),ysize(3)) :: uy2,uz2,rho2,phi2,gamma2,di2,ta2,tb2,tc2,td2
  real(mytype),dimension(zsize(1),zsize(2),zsize(3)) :: uz3,rho3,phi3,gamma3,di3,ta3,tb3,tc3

  integer :: ijk,nvect1,nvect2,nvect3,i,j,k,nxyz
  real(mytype) :: x,y,z

  nvect1=xsize(1)*xsize(2)*xsize(3)
  nvect2=ysize(1)*ysize(2)*ysize(3)
  nvect3=zsize(1)*zsize(2)*zsize(3)

  !X PENCILS
  do ijk=1,nvect1
    ta1(ijk,1,1)=rho1(ijk,1,1)*phi1(ijk,1,1)*ux1(ijk,1,1)
  enddo
  call derx (tb1,ta1,di1,sx,ffx,fsx,fwx,xsize(1),xsize(2),xsize(3),0)
  if (iprops.eq.0) then
    call derxx (ta1,phi1,di1,sx,sfxp,ssxp,swxp,xsize(1),xsize(2),xsize(3),1)
  else
    call derx (ta1,phi1,di1,sx,ffxp,fsxp,fwxp,xsize(1),xsize(2),xsize(3),1)
    tc1(:,:,:) = gamma1(:,:,:) * ta1(:,:,:)
    call derx (ta1,tc1,di1,sx,ffx,fsx,fwx,xsize(1),xsize(2),xsize(3),0)
    call transpose_x_to_y(gamma1, gamma2)
  endif

  call transpose_x_to_y(phi1,phi2)
  call transpose_x_to_y(uy1,uy2)
  call transpose_x_to_y(uz1,uz2)
  call transpose_x_to_y(rho1,rho2)

  !Y PENCILS
  do ijk=1,nvect2
    ta2(ijk,1,1)=rho2(ijk,1,1)*phi2(ijk,1,1)*uy2(ijk,1,1)
  enddo
  call dery (tb2,ta2,di2,sy,ffy,fsy,fwy,ppy,ysize(1),ysize(2),ysize(3),0)
  if (iprops.eq.0) then
    if (istret.ne.0) then 
      call deryy (ta2,phi2,di2,sy,sfyp,ssyp,swyp,ysize(1),ysize(2),ysize(3),1)
      call dery (tc2,phi2,di2,sy,ffy,fsy,fwy,ppy,ysize(1),ysize(2),ysize(3),0)
      do k=1,ysize(3)
        do j=1,ysize(2)
          do i=1,ysize(1)
            ta2(i,j,k)=ta2(i,j,k)*pp2y(j)-pp4y(j)*tc2(i,j,k)
          enddo
        enddo
      enddo
    else
      call deryy (ta2,phi2,di2,sy,sfyp,ssyp,swyp,ysize(1),ysize(2),ysize(3),1) 
    endif
  else
    call dery (ta2,phi2,di2,sy,ffyp,fsyp,fwyp,ppy,ysize(1),ysize(2),ysize(3),1)
    tc2(:,:,:) = gamma2(:,:,:) * ta2(:,:,:)
    call dery (ta2,tc2,di2,sy,ffy,fsy,fwy,ppy,ysize(1),ysize(2),ysize(3),0)
    call transpose_y_to_z(gamma2, gamma3)
  endif

  call transpose_y_to_z(phi2,phi3)
  call transpose_y_to_z(uz2,uz3)
  call transpose_y_to_z(rho2,rho3)

  !Z PENCILS
  do ijk=1,nvect3
    ta3(ijk,1,1)=rho3(ijk,1,1)*phi3(ijk,1,1)*uz3(ijk,1,1)
  enddo
  call derz (tb3,ta3,di3,sz,ffz,fsz,fwz,zsize(1),zsize(2),zsize(3),0)
  if (iprops.eq.0) then
    call derzz (ta3,phi3,di3,sz,sfzp,sszp,swzp,zsize(1),zsize(2),zsize(3),1)
  else
    call derz (ta3,phi3,di3,sz,ffzp,fszp,fwzp,zsize(1),zsize(2),zsize(3),1)
    tc3(:,:,:) = gamma3(:,:,:) * ta3(:,:,:)
    call derz (ta3,tc3,di3,sz,ffz,fsz,fwz,zsize(1),zsize(2),zsize(3),0)
  endif

  call transpose_z_to_y(ta3,tc2)
  call transpose_z_to_y(tb3,td2)

  !Y PENCILS ADD TERMS
  do ijk=1,nvect2
    tc2(ijk,1,1)=tc2(ijk,1,1)+ta2(ijk,1,1)
    td2(ijk,1,1)=td2(ijk,1,1)+tb2(ijk,1,1)
  enddo

  call transpose_y_to_x(tc2,tc1)
  call transpose_y_to_x(td2,td1)

  !X PENCILS ADD TERMS
  do ijk=1,nvect1
    ta1(ijk,1,1)=ta1(ijk,1,1)+tc1(ijk,1,1) !SECOND DERIVATIVE
    tb1(ijk,1,1)=tb1(ijk,1,1)+td1(ijk,1,1) !FIRST DERIVATIVE
  enddo

  do ijk=1,nvect1
    ta1(ijk,1,1)=xnu/sc*ta1(ijk,1,1)-tb1(ijk,1,1)
  enddo

  if (ilmn.ne.0) then
    phi1(:,:,:) = rho1(:,:,:)*phi1(:,:,:)
  endif

  !TIME ADVANCEMENT
  nxyz=xsize(1)*xsize(2)*xsize(3)  

  if ((nscheme.eq.1).or.(nscheme.eq.2)) then
    if ((nscheme.eq.1.and.itime.eq.1.and.ilit.eq.0).or.&
         (nscheme.eq.2.and.itr.eq.1)) then
      do ijk=1,nxyz
        phi1(ijk,1,1)=gdt(itr)*ta1(ijk,1,1)+phi1(ijk,1,1)
        phis1(ijk,1,1)=ta1(ijk,1,1)          
      enddo
    else
      do ijk=1,nxyz
        phi1(ijk,1,1)=adt(itr)*ta1(ijk,1,1)+bdt(itr)*phis1(ijk,1,1)+phi1(ijk,1,1)
        phis1(ijk,1,1)=ta1(ijk,1,1)          
      enddo
    endif
  endif

  if (nscheme.eq.3) then 
    if (nrank==0) print *,'Not ready'
    stop 
  endif

  if (nscheme==4) then
    if ((itime.eq.1).and.(ilit.eq.0)) then
      if (nrank==0) print *,'start with Euler',itime
      do ijk=1,nxyz !start with Euler
        phi1(ijk,1,1)=dt*ta1(ijk,1,1)+phi1(ijk,1,1)
        phis1(ijk,1,1)=ta1(ijk,1,1)          
      enddo
    else
      if  ((itime.eq.2).and.(ilit.eq.0)) then
        if (nrank==0) print *,'then with AB2',itime
        do ijk=1,nxyz
          phi1(ijk,1,1)=1.5_mytype*dt*ta1(ijk,1,1)-0.5_mytype*dt*phis1(ijk,1,1)+phi1(ijk,1,1)
          phiss1(ijk,1,1)=phis1(ijk,1,1)
          phis1(ijk,1,1)=ta1(ijk,1,1)
        enddo
      else
        do ijk=1,nxyz
          phi1(ijk,1,1)=adt(itr)*ta1(ijk,1,1)+bdt(itr)*phis1(ijk,1,1)+&
               cdt(itr)*phiss1(ijk,1,1)+phi1(ijk,1,1)
          phiss1(ijk,1,1)=phis1(ijk,1,1)
          phis1(ijk,1,1)=ta1(ijk,1,1)
         enddo
      endif
   endif
endif


end subroutine scalar

!!--------------------------------------------------------------------
!!  Subroutine: conv_density
!!
!! Description: Advances density in time for LMN.
!!
!!       Notes: The "diffusion" term in the continuity equation is
!!              given as:
!!
!!                (1 / (Re Pr T)) div(kappa grad(T))
!!
!!              however, we have p = rho T and grad(p) = 0, where p is
!!              the thermodynamic pressure in the LMN approximation.
!!              Therefore can make the substitution T = p / rho giving
!!
!!                (1 / (Re Pr (p / rho))) div(kappa grad(p / rho))
!!                  => (rho / (Re Pr)) div(kappa grad(1 / rho))
!!
!!              making use of grad(p) = 0. This saves
!!              memory/communication as would need to compute, store
!!              and transpose temperature array when we do this with
!!              density anyway.
!!--------------------------------------------------------------------
SUBROUTINE conv_density(ux1, uy1, uz1, rho1, di1, ta1, tb1, tc1, td1,&
     uy2, uz2, rho2, di2, ta2, tb2, tc2, td2, &
     uz3, rho3, divu3, di3, ta3, tb3, &
     epsi)
  
  USE param
  USE variables
  USE decomp_2d
  
  IMPLICIT NONE
  
  REAL(mytype), DIMENSION(xsize(1), xsize(2), xsize(3)) :: ux1, uy1, uz1
  REAL(mytype), DIMENSION(xsize(1), xsize(2), xsize(3)) :: rho1
  REAL(mytype), DIMENSION(xsize(1), xsize(2), xsize(3)) :: di1, ta1, tb1, tc1, td1, epsi
  
  REAL(mytype), DIMENSION(ysize(1), ysize(2), ysize(3)) :: uy2, uz2
  REAL(mytype), DIMENSION(ysize(1), ysize(2), ysize(3)) :: rho2
  REAL(mytype), DIMENSION(ysize(1), ysize(2), ysize(3)) :: di2, ta2, tb2, tc2, td2
  
  REAL(mytype), DIMENSION(zsize(1), zsize(2), zsize(3)) :: uz3
  REAL(mytype), DIMENSION(zsize(1), zsize(2), zsize(3)) :: rho3
  REAL(mytype), DIMENSION(zsize(1), zsize(2), zsize(3)) :: divu3
  REAL(mytype), DIMENSION(zsize(1), zsize(2), zsize(3)) :: di3, ta3, tb3

  REAL(mytype) :: invpe

  INTEGER :: ijk, nvect1, nvect2, nvect3

  nvect1 = xsize(1) * xsize(2) * xsize(3)
  nvect2 = ysize(1) * ysize(2) * ysize(3)
  nvect3 = zsize(1) * zsize(2) * zsize(3)

  invpe = xnu / sc

  !------------------------------------------------------------------------
  ! X PENCILS
  ! tb1 = diffusion
  ! ta1 = advection

  ! Advection term (non-conservative)
  CALL derx (ta1, rho1, di1, sx, ffxp, fsxp, fwxp, xsize(1), xsize(2), xsize(3), 1)
  ta1(:,:,:) = ux1(:,:,:) * ta1(:,:,:)

  ! Go to Y
  CALL transpose_x_to_y(rho1, rho2)
  CALL transpose_x_to_y(uy1, uy2)
  CALL transpose_x_to_y(uz1, uz2)

  !------------------------------------------------------------------------
  !Y PENCILS
  ! tb2 = diffusion
  ! ta2 = advection

  ! Advection term (non-conservative)
  CALL dery (ta2, rho2, di2, sy, ffyp, fsyp, fwyp, ppy, ysize(1), ysize(2), ysize(3), 1)
  ta2(:,:,:) = uy2(:,:,:) * ta2(:,:,:)

  ! Go to Z
  CALL transpose_y_to_z(rho2, rho3)
  CALL transpose_y_to_z(uz2, uz3)

  !------------------------------------------------------------------------
  ! Z PENCILS
  ! tb3 = diffusion
  ! ta3 = advection

  ! Advection term (non-conservative)
  ! XXX Also adds contribution from divu3
  CALL derz (ta3, rho3, di3, sz, ffzp, fszp, fwzp, zsize(1), zsize(2), zsize(3), 1)
  ta3(:,:,:) = uz3(:,:,:) * ta3(:,:,:) + rho3(:,:,:) * divu3(:,:,:)
  
  ! call derzz (tb3,rho3,di3,sz,sfzp,sszp,swzp,zsize(1),zsize(2),zsize(3),1)
  ! ta3(:,:,:) = ta3(:,:,:) - invpe * tb3(:,:,:)

  ! Get back to Y
  CALL transpose_z_to_y(ta3, td2)

  !------------------------------------------------------------------------
  !Y PENCILS ADD TERMS
  td2(:,:,:) = td2(:,:,:) + ta2(:,:,:)
  
  ! call deryy (tb2,rho2,di2,sy,sfyp,ssyp,swyp,ysize(1),ysize(2),ysize(3),1)
  ! td2(:,:,:) = td2(:,:,:) - invpe * tb2(:,:,:)

  ! Get back to X
  CALL transpose_y_to_x(td2, td1)

  !------------------------------------------------------------------------
  ! X PENCILS ADD TERMS and set negative (ddt rho = -div(rho u))
  ta1(:,:,:) = -(ta1(:,:,:) + td1(:,:,:)) !FIRST DERIVATIVE (CONV)
  
  ! call derxx (tb1,rho1,di1,sx,sfxp,ssxp,swxp,xsize(1),xsize(2),xsize(3),1)
  ! ta1(:,:,:) = ta1(:,:,:) + invpe * tb1(:,:,:)

  ! !! MMS Source term
  ! CALL density_source_mms(ta1)
  
ENDSUBROUTINE conv_density

!!--------------------------------------------------------------------
!!--------------------------------------------------------------------
SUBROUTINE convdiff_temperature(ux1, uy1, uz1, rho1, temperature1, di1, ta1, tb1,&
     uy2, uz2, rho2, temperature2, di2, ta2, tb2,&
     uz3, rho3, temperature3, di3, ta3, tb3)

  USE param
  USE variables
  USE decomp_2d
  
  IMPLICIT NONE

  REAL(mytype), DIMENSION(xsize(1), xsize(2), xsize(3)) :: ux1, uy1, uz1
  REAL(mytype), DIMENSION(xsize(1), xsize(2), xsize(3)) :: temperature1, rho1
  REAL(mytype), DIMENSION(xsize(1), xsize(2), xsize(3)) :: di1, ta1, tb1
  
  REAL(mytype), DIMENSION(ysize(1), ysize(2), ysize(3)) :: uy2, uz2
  REAL(mytype), DIMENSION(ysize(1), ysize(2), ysize(3)) :: temperature2, rho2
  REAL(mytype), DIMENSION(ysize(1), ysize(2), ysize(3)) :: di2, ta2, tb2
  
  REAL(mytype), DIMENSION(zsize(1), zsize(2), zsize(3)) :: uz3
  REAL(mytype), DIMENSION(zsize(1), zsize(2), zsize(3)) :: temperature3, rho3
  REAL(mytype), DIMENSION(zsize(1), zsize(2), zsize(3)) :: di3, ta3, tb3

  REAL(mytype) :: invpr

  invpr = 1._mytype / pr

  !!----------------------------------------------------------------
  ! Accumulate advection

  !----------------------------------------
  ! X-pencils
  CALL derx (tb1, temperature1, di1, sx, ffxp, fsxp, fwxp, xsize(1), xsize(2), xsize(3), 1)
  tb1(:,:,:) = ux1(:,:,:) * tb1(:,:,:)

  ! Go to Y
  CALL transpose_x_to_y(temperature1, temperature2)
  CALL transpose_x_to_y(uy1, uy2)
  CALL transpose_x_to_y(uz1, uz2)
  CALL transpose_x_to_y(rho1, rho2)

  !----------------------------------------
  !Y PENCILS
  CALL dery (tb2, temperature2, di2, sy, ffyp, fsyp, fwyp, ppy, ysize(1), ysize(2), ysize(3), 1)
  tb2(:,:,:) = uy2(:,:,:) * tb2(:,:,:)

  ! Go to Z
  CALL transpose_y_to_z(temperature2, temperature3)
  CALL transpose_y_to_z(uz2, uz3)
  CALL transpose_y_to_z(rho2, rho3)

  !----------------------------------------
  ! Z PENCILS
  CALL derz (tb3, temperature3, di3, sz, ffzp, fszp, fwzp, zsize(1), zsize(2), zsize(3), 1)
  tb3(:,:,:) = uz3(:,:,:) * tb3(:,:,:)

  !!----------------------------------------------------------------
  ! Add diffusion and get back to X
  ! XXX The diffusion term is equivalent to T div(u)
  call derzz (tb3,temperature3,di3,sz,sfzp,sszp,swzp,zsize(1),zsize(2),zsize(3),1)
  ta3(:,:,:) = (xnu * invpr / rho3(:,:,:)) * ta3(:,:,:) - tb3(:,:,:)

  CALL transpose_z_to_y(ta3, ta2)

  ta2(:,:,:) = ta2(:,:,:) - tb2(:,:,:)
  call deryy (tb2,temperature2,di2,sy,sfyp,ssyp,swyp,ysize(1),ysize(2),ysize(3),1)
  ta2(:,:,:) = ta2(:,:,:) + (xnu * invpr / rho2(:,:,:)) * tb2(:,:,:)
  
  CALL transpose_y_to_x(ta2, ta1)

  ta1(:,:,:) = ta1(:,:,:) - tb1(:,:,:)
  call derxx (tb1,temperature1,di1,sx,sfxp,ssxp,swxp,xsize(1),xsize(2),xsize(3),1)
  ta1(:,:,:) = ta1(:,:,:) + (xnu * invpr / rho1(:,:,:)) * tb1(:,:,:)
  
ENDSUBROUTINE convdiff_temperature

SUBROUTINE convdiff_massfrac(ux1, uy1, uz1, rho1, massfrac1, massfracs1, massfracss1, ta1, tb1, tc1, di1, &
     uy2, uz2, rho2, massfrac2, ta2, tb2, tc2, di2, &
     uz3, rho3, massfrac3, ta3, tb3, tc3, di3)

  USE param
  USE variables
  USE decomp_2d
  
  IMPLICIT NONE

  REAL(mytype), DIMENSION(xsize(1), xsize(2), xsize(3)) :: ux1, uy1, uz1, rho1
  REAL(mytype), DIMENSION(xsize(1), xsize(2), xsize(3)) :: massfrac1, massfracs1, massfracss1
  REAL(mytype), DIMENSION(xsize(1), xsize(2), xsize(3)) :: di1, ta1, tb1, tc1
  
  REAL(mytype), DIMENSION(ysize(1), ysize(2), ysize(3)) :: uy2, uz2, rho2
  REAL(mytype), DIMENSION(ysize(1), ysize(2), ysize(3)) :: massfrac2
  REAL(mytype), DIMENSION(ysize(1), ysize(2), ysize(3)) :: di2, ta2, tb2, tc2
  
  REAL(mytype), DIMENSION(zsize(1), zsize(2), zsize(3)) :: uz3, rho3
  REAL(mytype), DIMENSION(zsize(1), zsize(2), zsize(3)) :: massfrac3
  REAL(mytype), DIMENSION(zsize(1), zsize(2), zsize(3)) :: di3, ta3, tb3, tc3

  INTEGER :: ijk, nxyz

  REAL(mytype) :: invsc

  invsc = 1._mytype / sc

  nxyz = xsize(1) * xsize(2) * xsize(3)

  !!----------------------------------------------------------------
  ! Accumulate diffusion - advection

  !----------------------------------------
  ! X-pencils
  CALL derx (ta1, massfrac1, di1, sx, ffxp, fsxp, fwxp, xsize(1), xsize(2), xsize(3), 1)
  tb1(:,:,:) = rho1(:,:,:) * ta1(:,:,:)
  call derx (tc1,tb1,di1,sx,ffx,fsx,fwx,xsize(1),xsize(2),xsize(3),0)
  ta1(:,:,:) = (xnu * invsc / rho1(:,:,:)) * tc1(:,:,:) - ux1(:,:,:) * ta1(:,:,:)

  ! Go to Y
  CALL transpose_x_to_y(massfrac1, massfrac2)
  CALL transpose_x_to_y(uy1, uy2)
  CALL transpose_x_to_y(uz1, uz2)
  CALL transpose_x_to_y(rho1, rho2)

  !----------------------------------------
  !Y PENCILS
  CALL dery (ta2, massfrac2, di2, sy, ffyp, fsyp, fwyp, ppy, ysize(1), ysize(2), ysize(3), 1)
  tb2(:,:,:) = rho2(:,:,:) * ta2(:,:,:)
  CALL dery (tc2, tb2, di2, sy, ffy, fsy, fwy, ppy, ysize(1), ysize(2), ysize(3), 0)
  ta2(:,:,:) = (xnu * invsc / rho2(:,:,:)) * tc2(:,:,:) - uy2(:,:,:) * ta2(:,:,:)

  ! Go to Z
  CALL transpose_y_to_z(massfrac2, massfrac3)
  CALL transpose_y_to_z(uz2, uz3)
  CALL transpose_y_to_z(rho2, rho3)

  !----------------------------------------
  ! Z PENCILS
  CALL derz (ta3, massfrac3, di3, sz, ffzp, fszp, fwzp, zsize(1), zsize(2), zsize(3), 1)
  tb3(:,:,:) = rho3(:,:,:) * ta3(:,:,:)
  CALL derz (tc3, tb3, di3, sz, ffz, fsz, fwz, zsize(1), zsize(2), zsize(3), 0)
  ta3(:,:,:) = (xnu * invsc / rho3(:,:,:)) * tc3(:,:,:) - uz3(:,:,:) * ta3(:,:,:)

  ! Get back to X
  CALL transpose_z_to_y(ta3, tb2)
  ta2(:,:,:) = ta2(:,:,:) + tb2(:,:,:)
  CALL transpose_y_to_x(ta2, tb1)
  ta1(:,:,:) = ta1(:,:,:) + tb1(:,:,:)

  !! Integrate in time
  IF ((nscheme.EQ.1).OR.(nscheme.EQ.2)) THEN
    !! AB2 or RK3

    IF (((nscheme.EQ.1).AND.(itime.EQ.1).AND.(ilit.EQ.0)).OR.&
         ((nscheme.EQ.2).AND.(itr.EQ.1))) THEN
      massfrac1(:,:,:) = massfrac1(:,:,:) + gdt(itr) * ta1(:,:,:)
    ELSE
      massfrac1(:,:,:) = massfrac1(:,:,:) + adt(itr) * ta1(:,:,:) &
           + bdt(itr) * massfracs1(:,:,:)
    ENDIF
  ELSE IF (nscheme.EQ.3) THEN
    !! RK3
    IF (nrank.EQ.0) THEN
      PRINT *, "LMN: RK4 not ready!"
      STOP
    ENDIF
  ELSE
    !! AB3
    IF ((itime.EQ.1).AND.(ilit.EQ.0)) THEN
      IF (nrank.EQ.0) THEN
        PRINT  *, 'start with Euler', itime
      ENDIF
      massfrac1(:,:,:) = massfrac1(:,:,:) + dt * ta1(:,:,:)
    ELSE
      IF  ((itime.EQ.2).AND.(ilit.EQ.0)) THEN
        IF (nrank.EQ.0) THEN
          PRINT *, 'then with AB2', itime
        ENDIF
        massfrac1(:,:,:) = massfrac1(:,:,:) - 0.5_mytype * dt &
             * (massfracs1(:,:,:) - 3._mytype * ta1(:,:,:))
      ELSE
        massfrac1(:,:,:) = massfrac1(:,:,:) + adt(itr) * ta1(:,:,:) &
             + bdt(itr) * massfracs1(:,:,:) + cdt(itr) * massfracss1(:,:,:)
      ENDIF

      !! Update oldold stage
      massfracss1(:,:,:) = massfracs1(:,:,:)
    ENDIF
  ENDIF

  !! Update old stage
  massfracs1(:,:,:) = ta1(:,:,:)

  !! Limiting
  DO ijk = 1, nxyz
    massfrac1(ijk, 1, 1) = MAX(massfrac1(ijk, 1, 1), 0._mytype)
    massfrac1(ijk, 1, 1) = MIN(massfrac1(ijk, 1, 1), 1._mytype)
  ENDDO
  
ENDSUBROUTINE convdiff_massfrac

!!--------------------------------------------------------------------
!!  SUBROUTINE: calc_divu
!! DESCRIPTION: In LMN the divergence of velocity is given in terms of
!!              the temperature field, ensuring the gradient of
!!              thermodynamic pressure is zero.
!!--------------------------------------------------------------------
SUBROUTINE calc_divu(ta1, tb1, tc1, rho1, temperature1, massfrac1, kappa1, di1, &
     ta2, tb2, tc2, rho2, temperature2, massfrac2, kappa2, di2, &
     divu3, ta3, tb3, rho3, temperature3, massfrac3, kappa3, di3, &
     pressure0)

  USE param
  USE variables
  USE decomp_2d
  
  IMPLICIT NONE

  INTEGER i, j, k

  REAL(mytype), DIMENSION(xsize(1), xsize(2), xsize(3)) :: ta1, tb1, tc1, di1
  REAL(mytype), DIMENSION(xsize(1), xsize(2), xsize(3)), INTENT(IN) :: rho1, temperature1, massfrac1
  REAL(mytype), DIMENSION(xsize(1), xsize(2), xsize(3)), INTENT(OUT) :: kappa1
  REAL(mytype), DIMENSION(ysize(1), ysize(2), ysize(3)) :: ta2, tb2, tc2, di2
  REAL(mytype), DIMENSION(ysize(1), ysize(2), ysize(3)), INTENT(OUT) :: rho2, temperature2, massfrac2, kappa2
  REAL(mytype), DIMENSION(zsize(1), zsize(2), zsize(3)) :: ta3, tb3, di3
  REAL(mytype), DIMENSION(zsize(1), zsize(2), zsize(3)), INTENT(OUT) :: divu3, rho3, temperature3, massfrac3, kappa3
  REAL(mytype), INTENT(IN) :: pressure0

  REAL(mytype) :: invpressure0, invpr, invsc
  
  IF (ilmn.NE.0) THEN
    invpressure0 = 1._mytype / pressure0
    invpr = 1._mytype / pr
    invsc = 1._mytype / sc
    
    !-------------------------------------------------------------------
    ! X pencil
    !-------------------------------------------------------------------

    ! Temperature
    IF (iprops.EQ.0) THEN
      ! Calculate divergence of velocity using 2nd derivatives for accuracy
      CALL derxx (ta1, temperature1, di1, sx, sfxp, ssxp, swxp, xsize(1), xsize(2), xsize(3), 1)
    ELSE
      ! Variable properties, must retain conservative form to ensure mass conservation!
    
      ! Update thermal conductivity
      CALL calckappa(kappa1, temperature1)

      CALL derx (ta1, temperature1, di1, sx, ffxp, fsxp, fwxp, xsize(1), xsize(2), xsize(3), 1)
      tb1(:,:,:) = kappa1(:,:,:) * ta1(:,:,:)
      CALL derx (ta1, tb1, di1, sx, ffx, fsx, fwx, xsize(1), xsize(2), xsize(3), 0)
      CALL transpose_x_to_y(kappa1, kappa2)
    ENDIF
    ta1(:,:,:) = (xnu * invpr / temperature1(:,:,:)) * ta1(:,:,:)

    ! Massfrac
    if (imulticomponent.ne.0) then
      call derx (tb1,massfrac1,di1,sx,ffxp,fsxp,fwxp,xsize(1),xsize(2),xsize(3),1)
      tb1(:,:,:) = rho1(:,:,:) * tb1(:,:,:)
      call derx (tc1,tb1,di1,sx,ffx,fsx,fwx,xsize(1),xsize(2),xsize(3),0)
      ta1(:,:,:) = ta1(:,:,:) + (xnu * invsc &
           * (dens2 - dens1) / ((dens2 - dens1) * massfrac1(:,:,:) + dens1)) * tc1(:,:,:)
    endif
    
    ! Transpose to Y
    CALL transpose_x_to_y(rho1, rho2)
    CALL transpose_x_to_y(temperature1, temperature2)
    CALL transpose_x_to_y(massfrac1, massfrac2)
    CALL transpose_x_to_y(ta1, ta2)
    
    !-------------------------------------------------------------------
    ! Y pencil
    !-------------------------------------------------------------------

    ! Temperature
    IF (iprops.EQ.0) THEN
      ! Calculate divergence of velocity using 2nd derivatives for accuracy
      IF(istret.NE.0) THEN
        CALL deryy (tb2, temperature2, di2, sy, sfyp, ssyp, swyp, ysize(1), ysize(2), ysize(3), 1)
        CALL dery (tc2, temperature2, di2, sy, ffyp, fsyp, fwyp, ppy, ysize(1), ysize(2), ysize(3), 1)
        DO k = 1, ysize(3)
          DO j = 1, ysize(2)
            DO i = 1, ysize(1)
              tb2(i, j, k) = tb2(i, j, k) * pp2y(j) - pp4y(j) * tc2(i, j, k)
            ENDDO
          ENDDO
        ENDDO
      ELSE
        CALL deryy (tb2, temperature2, di2, sy, sfyp, ssyp, swyp, ysize(1), ysize(2), ysize(3), 1)
      ENDIF
    ELSE
      ! Variable properties, must retain conservative form to ensure mass conservation!
      CALL dery (tb2, temperature2, di2, sy, ffyp, fsyp, fwyp, ppy, ysize(1), ysize(2), ysize(3), 1)
      tc2(:,:,:) = kappa2(:,:,:) * tb2(:,:,:)
      CALL dery (tb2, tc2, di2, sy, ffy, fsy, fwy, ppy, ysize(1), ysize(2), ysize(3), 0)
      CALL transpose_y_to_z(kappa2, kappa3)
    ENDIF
    ta2(:,:,:) = ta2(:,:,:) + (xnu * invpr / temperature2(:,:,:)) * tb2(:,:,:)

    ! Massfrac
    if (imulticomponent.ne.0) then
      CALL dery (tb2, massfrac2, di2, sy, ffyp, fsyp, fwyp, ppy, ysize(1), ysize(2), ysize(3), 1)
      tb2(:,:,:) = rho2(:,:,:) * tb2(:,:,:)
      CALL dery (tc2, tb2, di2, sy, ffy, fsy, fwy, ppy, ysize(1), ysize(2), ysize(3), 0)
      ta2(:,:,:) = ta2(:,:,:) + (xnu * invsc &
           * (dens2 - dens1) / ((dens2 - dens1) * massfrac1(:,:,:) + dens1)) * tc2(:,:,:)
    endif
    
    ! Transpose to Z
    CALL transpose_y_to_z(rho2, rho3)
    CALL transpose_y_to_z(temperature2, temperature3)
    CALL transpose_y_to_z(massfrac2, massfrac3)
    CALL transpose_y_to_z(ta2, ta3)
    
    !-------------------------------------------------------------------
    ! Z pencil
    !-------------------------------------------------------------------

    ! Temperature
    IF (iprops.EQ.0) THEN
      ! Calculate divergence of velocity using 2nd derivatives for accuracy
      CALL derzz (divu3, temperature3, di3, sz, sfzp, sszp, swzp, zsize(1), zsize(2), zsize(3), 1)
    ELSE
      ! Variable properties, must retain conservative form to ensure mass conservation!
      CALL derz (divu3, temperature3, di3, sz, ffzp, fszp, fwzp, zsize(1), zsize(2), zsize(3), 1)
      tb3(:,:,:) = kappa3(:,:,:) * divu3(:,:,:)
      CALL derz (divu3, tb3, di3, sz, ffz, fsz, fwz, zsize(1), zsize(2), zsize(3), 0)
    ENDIF
    divu3(:,:,:) = ta3(:,:,:) + (xnu * invpr / temperature3(:,:,:)) * divu3(:,:,:)

    ! Massfrac
    if (imulticomponent.ne.0) then
      CALL derz (tb3, massfrac3, di3, sz, ffzp, fszp, fwzp, zsize(1), zsize(2), zsize(3), 1)
      tb3(:,:,:) = rho3(:,:,:) * tb3(:,:,:)
      CALL derz (ta3, tb3, di3, sz, ffz, fsz, fwz, zsize(1), zsize(2), zsize(3), 0)
      divu3(:,:,:) = divu3(:,:,:) + (xnu * invsc &
           * (dens2 - dens1) / ((dens2 - dens1) * massfrac3(:,:,:) + dens1)) * ta3(:,:,:)
    endif

    ! So far have rho * divu, want divu
    divu3(:,:,:) = divu3(:,:,:) / rho3(:,:,:)
    
    ! XXX add dpdt and additional source terms
  ELSE
    temperature2(:,:,:) = 1._mytype
    temperature3(:,:,:) = 1._mytype

    divu3(:,:,:) = 0._mytype
  ENDIF
    
  !-------------------------------------------------------------------
  ! XXX Density and temperature fields are now up to date in all
  !     pencils.
  !     Divergence of velocity is only known in Z pencil.
  !-------------------------------------------------------------------
    
ENDSUBROUTINE calc_divu

!!--------------------------------------------------------------------
!!  SUBROUTINE: calctemp_eos
!! DESCRIPTION: Given the new density field, calculate temperature
!!              using the equation of state.
!!--------------------------------------------------------------------
SUBROUTINE calctemp_eos(temperature1, rho1, massfrac1, pressure0, arrsize)

  USE variables
  USE param
  USE decomp_2d

  IMPLICIT NONE

  INTEGER, DIMENSION(3), INTENT(IN) :: arrsize

  REAL(mytype), DIMENSION(arrsize(1), arrsize(2), arrsize(3)), INTENT(OUT) :: temperature1
  REAL(mytype), DIMENSION(arrsize(1), arrsize(2), arrsize(3)), INTENT(IN) :: rho1, massfrac1

  REAL(mytype), INTENT(IN) :: pressure0
  REAL(mytype) :: W1, W2, Wbar
  REAL(mytype) :: dmulticomponent

  INTEGER :: ijk, nxyz

  IF (imulticomponent.EQ.0) THEN
    dmulticomponent = 0._mytype
  ELSE
    dmulticomponent = 1._mytype
  ENDIF

  !! Molecular weights @ STP = density * R
  !! (Assumes STP is T = 1, P = 1.
  W1 = dens1
  W2 = dens2

  nxyz = xsize(1) * xsize(2) * xsize(3)
  DO ijk = 1, nxyz
    Wbar = (1._mytype - massfrac1(ijk, 1, 1)) / W1 + massfrac1(ijk, 1, 1) / W2
    Wbar = (1._mytype - dmulticomponent) + dmulticomponent / Wbar
    temperature1(ijk, 1, 1) = pressure0 / (rho1(ijk, 1, 1) / Wbar)
  ENDDO
  
ENDSUBROUTINE calctemp_eos

!!--------------------------------------------------------------------
!!  SUBROUTINE: calcrho_eos
!! DESCRIPTION: Given the new temperature field, calculate density
!!              using the equation of state.
!!--------------------------------------------------------------------
SUBROUTINE calcrho_eos(rho1, temperature1, massfrac1, pressure0, arrsize)

  USE variables
  USE param
  USE decomp_2d

  IMPLICIT NONE

  INTEGER, DIMENSION(3), INTENT(IN) :: arrsize

  REAL(mytype), DIMENSION(arrsize(1), arrsize(2), arrsize(3)), INTENT(IN) :: temperature1, massfrac1
  REAL(mytype), DIMENSION(arrsize(1), arrsize(2), arrsize(3)), INTENT(OUT) :: rho1

  REAL(mytype), INTENT(IN) :: pressure0
  REAL(mytype) :: W1, W2, Wbar
  REAL(mytype) :: dmulticomponent

  INTEGER :: ijk, nxyz

  IF (imulticomponent.EQ.0) THEN
    dmulticomponent = 0._mytype
  ELSE
    dmulticomponent = 1._mytype
  ENDIF

  !! Molecular weights @ STP = density * R
  !! (Assumes STP is T = 1, P = 1.
  W1 = dens1
  W2 = dens2

  nxyz = xsize(1) * xsize(2) * xsize(3)
  DO ijk = 1, nxyz
    Wbar = (1._mytype - massfrac1(ijk, 1, 1)) / W1 + massfrac1(ijk, 1, 1) / W2
    Wbar = (1._mytype - dmulticomponent) + dmulticomponent / Wbar
    rho1(ijk, 1, 1) = pressure0 / (temperature1(ijk, 1, 1) / Wbar)
  ENDDO
  
ENDSUBROUTINE calcrho_eos

!!--------------------------------------------------------------------
!!  SUBROUTINE: calcvisc
!! DESCRIPTION: Calculate the fluid viscosity as a function of
!!              temperature/density.
!!--------------------------------------------------------------------
SUBROUTINE calcvisc(mu1, mu2, mu3, rho1, temperature1, massfrac1)

  USE param
  USE variables
  USE decomp_2d
  
  IMPLICIT NONE

  REAL(mytype), DIMENSION(xsize(1), xsize(2), xsize(3)), INTENT(IN) :: massfrac1, temperature1, rho1
  REAL(mytype), DIMENSION(xsize(1), xsize(2), xsize(3)) :: mu1
  REAL(mytype), DIMENSION(ysize(1), ysize(2), ysize(3)) :: mu2
  REAL(mytype), DIMENSION(zsize(1), zsize(2), zsize(3)), INTENT(OUT) :: mu3

  if (iprops.ne.0) then
     !! Enable variable properties

     !! Corresponds to constant /kinematic/ viscosity
     mu1(:,:,:) = rho1(:,:,:)

     !! Transpose up to z-pencils where it is needed
     !! Also updates mu2 in the process
     call transpose_x_to_y(mu1, mu2)
     call transpose_y_to_z(mu2, mu3)
  else
     !! Use fixed properties
     mu3(:,:,:) = 1._mytype
  endif
  
ENDSUBROUTINE calcvisc

!!--------------------------------------------------------------------
!!  SUBROUTINE: calckappa
!! DESCRIPTION: Calculate the thermal conductivity of the fluid as a
!!              function of temperature.
!!--------------------------------------------------------------------
SUBROUTINE calckappa(kappa1, temperature1)

  USE param
  USE variables
  USE decomp_2d
  
  IMPLICIT NONE

  REAL(mytype), DIMENSION(xsize(1), xsize(2), xsize(3)), INTENT(IN) :: temperature1
  REAL(mytype), DIMENSION(xsize(1), xsize(2), xsize(3)), INTENT(OUT) :: kappa1

  if (iprops.ne.0) then
    !! Enable variable properties

    ! Just set kappa=1 for now
    kappa1(:,:,:) = 1._mytype
  else
    !! Use fixed properties
    kappa1(:,:,:) = 1._mytype
  endif
ENDSUBROUTINE calckappa

!!--------------------------------------------------------------------
!!  SUBROUTINE: calcgamma
!! DESCRIPTION: Calculate the scalar diffusion coefficient as a
!!              function of temperature.
!!--------------------------------------------------------------------
SUBROUTINE calcgamma(gamma1, temperature1)

  USE param
  USE variables
  USE decomp_2d
  
  IMPLICIT NONE

  REAL(mytype), DIMENSION(xsize(1), xsize(2), xsize(3)), INTENT(IN) :: temperature1
  REAL(mytype), DIMENSION(xsize(1), xsize(2), xsize(3)), INTENT(OUT) :: gamma1

  if (iprops.ne.0) then
    !! Enable variable properties

    ! Just set mu=1 for now
    gamma1(:,:,:) = 1._mytype
  else
    !! Use fixed properties
    gamma1(:,:,:) = 1._mytype
  endif
  
ENDSUBROUTINE calcgamma
  
!!--------------------------------------------------------------------
!! SUBROUTINE: density_source_mms
!! DESCIPTION: Computes the source term for the density equation in
!!             Method of Manufactured Solutions test and adds it to
!!             the stress/diffusion term.
!!--------------------------------------------------------------------
SUBROUTINE density_source_mms(mms)

  USE var

  IMPLICIT NONE

  REAL(mytype), DIMENSION(xsize(1),xsize(2),xsize(3)) :: mms

  REAL(mytype) :: x,y,z
  REAL(mytype) :: xspec,yspec,zspec
  INTEGER :: i,j,k

  REAL(mytype) :: rhomms, rho0
  REAL(mytype) :: Tmms
  REAL(mytype) :: press0
  REAL(mytype) :: SrhoX, SrhoY, SrhoZ
  REAL(mytype) :: MMSource
  REAL(mytype) :: SINX, SINY, SINZ
  REAL(mytype) :: COSX, COSY, COSZ

  press0 = 1._mytype
  rho0 = 2._mytype

  DO k = 1,xsize(3)
    z = float(k + xstart(3) - 2) * dz
    zspec = (2._mytype * PI) * (z / zlz)
    DO j = 1,xsize(2)
      y = float(j + xstart(2) - 2) * dy
      yspec = (2._mytype * PI) * (y / yly)
      DO i = 1, xsize(1)
        x = float(i + xstart(1) - 2) * dx
        xspec = (2._mytype * PI) * (x / xlx)

        SINX = SIN(xspec)
        SINY = SIN(yspec)
        SINZ = SIN(zspec)
        COSX = COS(xspec)
        COSY = COS(yspec)
        COSZ = COS(zspec)

        rhomms = rho0 + SIN(xspec) * SIN(yspec) * SIN(zspec)
        Tmms = press0 / rhomms

        !!
        !! Compute nabla.nabla T
        !!

        ! d/dx( d/dx T )
        SrhoX = rhomms * SINX
        SrhoX = SrhoX + 2._mytype * COSX**2 * SINY * SINZ
        SrhoX = SrhoX * SINY * SINZ / (xlx**2)

        ! d/dy( d/dy T )
        SrhoY = rhomms * SINY
        SrhoY = SrhoY + 2._mytype * SINX * COSY**2 * SINZ
        SrhoY = SrhoY * SINX * SINZ / (yly**2)

        ! d/dz( d/dz T )
        SrhoZ = rhomms * SINZ
        SrhoZ = SrhoZ + 2._mytype * SINX * SINY * COSZ**2
        SrhoZ = SrhoZ * SINX * SINY / (zlz**2)

        MMSource = SrhoX + SrhoY + SrhoZ
        MMSource = (4._mytype * PI**2 * press0 / rhomms**3) * MMSource

        !!
        !! Compute divu = (1 / (Re Pr T)) * nabla.nabla T / rho
        !!
        MMSource = MMSource * (xnu / (pr * (rhomms * Tmms)))

        !!
        !! Finally: S_rho = rho * divu
        !!
        MMSource = rhomms * MMSource        

        mms(i,j,k) = mms(i,j,k) + MMSource
      ENDDO ! End loop over i
    ENDDO ! End loop over j
  ENDDO ! End loop over k

ENDSUBROUTINE density_source_mms
  
!!--------------------------------------------------------------------
!! SUBROUTINE: momentum_source_mms
!! DESCIPTION: Computes the source term for the momentum equations in
!!             Method of Manufactured Solutions test and adds it to
!!             the stress/diffusion term
SUBROUTINE momentum_source_mms(mmsx1, mmsy1, mmsz1)

  USE var

  IMPLICIT NONE

  REAL(mytype), DIMENSION(xsize(1),xsize(2),xsize(3)) :: mmsx1, mmsy1, mmsz1

  REAL(mytype) :: x,y,z
  REAL(mytype) :: xspec,yspec,zspec
  INTEGER :: i,j,k

  REAL(mytype) :: umms, vmms, wmms
  REAL(mytype) :: rhomms, rho_0
  REAL(mytype) :: press0
  REAL(mytype) :: Tmms
  REAL(mytype) :: divumms
  REAL(mytype) :: MMSource

  REAL(mytype) :: SINX, SINY, SINZ, SINHALFX, SINHALFY, SINHALFZ
  REAL(mytype) :: COSX, COSY, COSZ, COSHALFX, COSHALFY, COSHALFZ

  rho_0 = 2._mytype
  press0 = 1._mytype
  
  DO k = 1,xsize(3)
    z = float(k + xstart(3) - 2) * dz
    zspec = (2._mytype * PI) * (z / zlz)
    DO j = 1,xsize(2)
      y = float(j + xstart(2) - 2) * dy
      yspec = (2._mytype * PI) * (y / yly)
      DO i = 1, xsize(1)
        x = float(i + xstart(1) - 2) * dx
        xspec = (2._mytype * PI) * (x / xlx)

        SINX = SIN(xspec)
        SINY = SIN(yspec)
        SINZ = SIN(zspec)
        COSX = COS(xspec)
        COSY = COS(yspec)
        COSZ = COS(zspec)
        SINHALFX = SIN(0.5_mytype * xspec)
        SINHALFY = SIN(0.5_mytype * yspec)
        SINHALFZ = SIN(0.5_mytype * zspec)
        COSHALFX = COS(0.5_mytype * xspec)
        COSHALFY = COS(0.5_mytype * yspec)
        COSHALFZ = COS(0.5_mytype * zspec)

        umms =              (xlx / (2._mytype * PI)) * SINX * COSY * COSZ
        vmms =              (yly / (2._mytype * PI)) * COSX * SINY * COSZ
        wmms = -2._mytype * (zlz / (2._mytype * PI)) * COSX * COSY * SINZ

        rhomms = rho_0 + SINX * SINY * SINZ
        Tmms = press0 / rhomms

        divumms = (rhomms * SINX + 2._mytype * COSX**2 * SINY * SINZ) &
             * SINY * SINZ / xlx**2 &
             + (rhomms * SINY + 2._mytype * SINX * COSY**2 * SINZ) &
             * SINX * SINZ / yly**2 &
             + (rhomms * SINZ + 2._mytype * SINX * SINY * COSZ**2) &
             * SINX * SINY / zlz**2
        divumms = (4._mytype * PI**2 * press0 / rhomms**3) * divumms
        divumms = ((xnu / (pr * (rhomms * Tmms))) * divumms)
        
        !! XMOM

        ! Advection
        MMSource = 8._mytype * (SINHALFY**4 - SINHALFY**2) &
             - 4._mytype * (SINHALFZ**4 - SINHALFZ**2) + 1._mytype
        MMSource = (xlx / (2._mytype * PI)) * rhomms * MMSource * SINX * COSX
        mmsx1(i,j,k) = mmsx1(i,j,k) + MMSource

        ! The first half of the viscous stress tensor (grad u + grad^T u)
        MMSource = (2._mytype * PI * xnu / (xlx * yly**2 * zlz**2)) &
             * (xlx**2 * yly**2 + xlx**2 * zlz**2 + yly**2 * zlz**2) &
             * SINX * COSY * COSZ
        mmsx1(i,j,k) = mmsx1(i,j,k) + MMSource

        ! The bulk component of viscous stress tensor
        MMSource = xlx**2 * yly**2 * rhomms**2 * SINY * SINZ &
             + 2._mytype * xlx**2 * yly**2 * rhomms &
             * (12._mytype * SINHALFZ**4 - 12._mytype * SINHALFZ**2 + 2._mytype) &
             * SINX * SINY**2
        MMSource = MMSource - 6._mytype * xlx**2 * yly**2 * SINX**2 * SINY**3 * SINZ * COSZ**2 &
             + xlx**2 * zlz**2 * rhomms**2 * SINY * SINZ
        MMSource = MMSource + 2._mytype * xlx**2 * zlz**2 * rhomms &
             * (12._mytype * SINHALFY**4 - 12._mytype * SINHALFY**2 + 2._mytype) * SINX * SINZ**2
        MMSource = MMSource - 6._mytype * xlx**2 * zlz**2 * SINX**2 * SINY * SINZ**3 * COSY**2 &
             + yly**2 * zlz**2 * rhomms**2 * SINY * SINZ &
             - 6._mytype * yly**2 * zlz**2 * rhomms * SINX * SINY**2 * SINZ**2
        MMSource = MMSource - 6._mytype * yly**2 * zlz**2 * SINY**3 * SINZ**3 * COSX**2
        MMSource = (16._mytype * PI**3 * COSX / (3._mytype * (pr / xnu**2) &
             * xlx**3 * yly**2 * zlz**2 * rhomms**4)) * MMSource
        mmsx1(i,j,k) = mmsx1(i,j,k) + MMSource

        !! YMOM

        ! Advection
        MMSource = 8._mytype * (SINHALFX**4 - SINHALFX**2) &
             - 4._mytype * (SINHALFZ**4 - SINHALFZ**2) + 1._mytype
        MMSource = (yly / (2._mytype * PI)) * rhomms * MMSource * SINY * COSY
        mmsy1(i,j,k) = mmsy1(i,j,k) + MMSource

        ! The first half of the viscous stress tensor (grad u + grad^T u)
        MMSource = (2._mytype * PI * xnu / (xlx**2 * yly * zlz**2)) &
             * (xlx**2 * yly**2 + xlx**2 * zlz**2 + yly**2 * zlz**2) &
             * COSX * SINY * COSZ
        mmsy1(i,j,k) = mmsy1(i,j,k) + MMSource
        
        ! The bulk component of viscous stress tensor
        MMSource = xlx**2 * yly**2 * rhomms**2 * SINX * SINZ &
             + 2._mytype * xlx**2 * yly**2 * rhomms &
             * (12._mytype * SINHALFZ**4 - 12._mytype * SINHALFZ**2 + 2._mytype) * SINX**2 * SINY
        MMSource = MMSource - 6._mytype * xlx**2 * yly**2 * SINX**3 * SINY**2 * SINZ * COSZ**2 &
             + xlx**2 * zlz**2 * rhomms**2 * SINX * SINZ
        MMSource = MMSource - 6._mytype * xlx**2 * zlz**2 * rhomms * SINX**2 * SINY * SINZ**2 &
             - 6._mytype * xlx**2 * zlz**2 * SINX**3 * SINZ**3 * COSY**2
        MMSource = MMSource + yly**2 * zlz**2 * rhomms**2 * SINX * SINZ &
             + 2._mytype * yly**2 * zlz**2 * rhomms &
             * (12._mytype * SINHALFX**4 - 12._mytype * SINHALFX**2 + 2._mytype) &
             * SINY * SINZ**2
        MMSource = MMSource - 6._mytype * yly**2 * zlz**2 * SINX * SINY**2 * SINZ**3 * COSX**2
        MMSource = (16._mytype * PI**3 * COSY &
             / (3._mytype * (pr / xnu**2) * xlx**2 * yly**3 * zlz**2 * rhomms**4)) * MMSource
        mmsy1(i,j,k) = mmsy1(i,j,k) + MMSource

        !! ZMOM

        ! Advection
        MMSource = 4._mytype * ((SINHALFX**4 - SINHALFX**2) &
             + (SINHALFY**4 - SINHALFY**2)) + 2._mytype
        MMSource = (zlz / PI) * rhomms * MMSource * SINZ * COSZ
        mmsz1(i,j,k) = mmsz1(i,j,k) + MMSource
         
        ! The first half of the viscous stress tensor (grad u + grad^T u)
        MMSource = -(4._mytype * PI * XNU / (xlx**2 * yly**2 * zlz)) &
             * (xlx**2 * yly**2 + xlx**2 * zlz**2 + yly**2 * zlz**2) &
             * COSX * COSY * SINZ
        mmsz1(i,j,k) = mmsz1(i,j,k) + MMSource

        ! The bulk component of viscous stress tensor
        MMSource = xlx**2 * yly**2 * rhomms**2 * SINX * SINY &
             - 6._mytype * xlx**2 * yly**2 * rhomms * SINX**2 * SINY**2 * SINZ
        MMSource = MMSource - 6._mytype * xlx**2 * yly**2 * SINX**3 * SINY**3 * COSZ**2 &
             + xlx**2 * zlz**2 * rhomms**2 * SINX * SINY
        MMSource = MMSource + 2._mytype * xlx**2 * zlz**2 * rhomms &
             * (12._mytype * SINHALFY**4 - 12._mytype * SINHALFY**2 + 2._mytype) * SINX**2 * SINZ
        MMSource = MMSource - 6._mytype * xlx**2 * zlz**2 * SINX**3 * SINY * SINZ**2 * COSY**2 &
             + yly**2 * zlz**2 * rhomms**2 * SINX * SINY
        MMSource = MMSource + 2._mytype * yly**2 * zlz**2 * rhomms &
             * (12._mytype * SINHALFX**4 - 12._mytype * SINHALFX**2 + 2._mytype) * SINY**2 * SINZ
        MMSource = MMSource - 6._mytype * yly**2 * zlz**2 * SINX * SINY**3 * SINZ**2 * COSX**2
        MMSource = (16._mytype * PI**3 * COSZ / (3._mytype * (pr / xnu**2) &
             * xlx**2 * yly**2 * zlz**3 * rhomms**4)) * MMSource
        mmsz1(i,j,k) = mmsz1(i,j,k) + MMSource

        ! Correction for quasi-skew symmetry
        mmsx1(i,j,k) = mmsx1(i,j,k) + 0.5_mytype * umms * rhomms * divumms
        mmsy1(i,j,k) = mmsy1(i,j,k) + 0.5_mytype * vmms * rhomms * divumms
        mmsz1(i,j,k) = mmsz1(i,j,k) + 0.5_mytype * wmms * rhomms * divumms

      ENDDO ! End loop over i
    ENDDO ! End loop over j
  ENDDO ! End loop over k

ENDSUBROUTINE momentum_source_mms

!!--------------------------------------------------------------------
!!  SUBROUTINE: entrainment_bcy
!! DESCRIPTION: Implements entrainment boundary conditions on y
!!              boundary.
!!       NOTE : In Z stencil, based on work of Ioannou Vasilis.
!!--------------------------------------------------------------------
SUBROUTINE entrainment_bcy(ux3, uy3, uz3, clx3, cly3, clz3)

  USE decomp_2d
  USE variables
  USE param
  
  IMPLICIT NONE

  REAL(mytype), DIMENSION(zsize(1), zsize(2), zsize(3)), INTENT(IN) :: ux3, uy3, uz3
  REAL(mytype), DIMENSION(zsize(1), zsize(2), zsize(3)) :: clx3, cly3, clz3

  REAL(mytype) :: uu1, uv1, uw1
  REAL(mytype) :: y, z, yc, zc, ya, x
  REAL(mytype) :: x1, x2, y1, y2, r1, r2, r1r2ratio
  REAL(mytype) :: l_fringe, xph_fringe
  INTEGER :: i, j, k, iph_fringe

  l_fringe = 0.1_mytype * xlx
  xph_fringe = xlx - l_fringe

  IF (ncly.EQ.2) THEN
    DO i = 1, zsize(1)
      x = (i + zstart(1) - 2) * dx
      IF (x.GT.xph_fringe) THEN
        EXIT
      ELSE
        iph_fringe = i
      ENDIF
    ENDDO

    yc = yly / 2._mytype
    zc = zlz / 2._mytype
    IF (zstart(2).EQ.1) THEN
      j = 1
      y = -yc
      DO k = 1, zsize(3)
        !z = dz * (k - 1) - zc
        z = (k + zstart(3) - 2) * dz - zc
        x2 = y
        y2 = z
        x1 = y + dy
        y1 = y2 * x1 / x2
        r1 = SQRT(x1**2 + y1**2)
        r2 = SQRT(x2**2 + y2**2)
        r1r2ratio = r1 / r2
        IF (r1.GT.r2) THEN
           PRINT *, "Bug1 in entrainment_bcy"
           STOP
        ELSE
          IF (k.EQ.1) THEN ! First z-point
            DO i = 1, zsize(1)
              clx3(i, j, k) = ux3(i, j + 1, k + 1)
              cly3(i, j, k) = uy3(i, j + 1, k + 1) * r1r2ratio
              clz3(i, j, k) = uz3(i, j + 1, k + 1) * r1r2ratio
            ENDDO
          ELSEIF (k.EQ.((nz - 1) / 2 + 1)) THEN ! Mid z-point
            DO i = 1, zsize(1)
              clx3(i, j, k) = ux3(i, j + 1, k)
              cly3(i, j, k) = uy3(i, j + 1, k) * r1r2ratio
              clz3(i, j, k) = uz3(i, j + 1, k) * r1r2ratio
            ENDDO
          ELSEIF (k.EQ.nz) THEN ! Final z-point
            DO i = 1, zsize(1)
              clx3(i, j, k) = ux3(i, j + 1, k - 1)
              cly3(i, j, k) = uy3(i, j + 1, k - 1) * r1r2ratio
              clz3(i, j, k) = uz3(i, j + 1, k - 1) * r1r2ratio
            ENDDO
          ELSE ! General z-point
            IF (z.GT.0._mytype) THEN
              ya = y2 - dz
              DO i = 1, zsize(1)
                uu1 = ux3(i, j + 1, k - 1) &
                     + (ux3(i, j + 1, k) - ux3(i, j + 1, k - 1)) * (y1 - ya) / (y2 - ya)
                uv1 = uy3(i, j + 1, k - 1) &
                     + (uy3(i, j + 1, k) - uy3(i, j + 1, k - 1)) * (y1 - ya) / (y2 - ya)
                uw1 = uz3(i, j + 1, k - 1) &
                     + (uz3(i, j + 1, k) - uz3(i, j + 1, k - 1)) * (y1 - ya) / (y2 - ya)
                
                clx3(i, j, k) = uu1
                cly3(i, j, k) = uv1 * r1r2ratio
                clz3(i, j, k) = uw1 * r1r2ratio
              ENDDO
            ELSEIF (z.LT.0._mytype) THEN
              ya = y2 + dz
              DO i = 1, zsize(1)
                uu1 = ux3(i, j + 1, k + 1) &
                     + (ux3(i, j + 1, k + 1) - ux3(i, j + 1, k)) * (y1 - ya) / (ya - y2)
                uv1 = uy3(i, j + 1, k + 1) &
                     + (uy3(i, j + 1, k + 1) - uy3(i, j + 1, k)) * (y1 - ya) / (ya - y2)
                uw1 = uz3(i, j + 1, k + 1) &
                     + (uz3(i, j + 1, k + 1) - uz3(i, j + 1, k)) * (y1 - ya) / (ya - y2)

                clx3(i, j, k) = uu1
                cly3(i, j, k) = uv1 * r1r2ratio
                clz3(i, j, k) = uw1 * r1r2ratio
              ENDDO
            ELSE ! z = 0
               PRINT *, "Error, z=0 should not happen!"
               STOP
            ENDIF
         ENDIF ! End checking where in z we are

         ! Set fringe
         DO i = iph_fringe + 1, zsize(1)
            cly3(i, j, k) = 0._mytype
         ENDDO
       ENDIF
      ENDDO !! End loop over k
    ENDIF !! End if (ztstart(2).eq.1), i.e. first y boundary

    IF (zend(2).EQ.ny) THEN
      j = zsize(2)
      y = yc
      DO k = 1, zsize(3)
        !z = dz * (k - 1) - zc
        z = (k + zstart(3) - 2) * dz - zc
        x2 = y
        y2 = z
        x1 = y - dy
        y1 = y2 * x1 / x2
        r1 = SQRT(x1**2 + y1**2)
        r2 = SQRT(x2**2 + y2**2)
        r1r2ratio = r1 / r2
        IF (r1.GT.r2) THEN
          PRINT *, "Bug2 in entrainment_bcy"
          STOP
        ELSE
          IF (k.EQ.1) THEN ! First z-point
            DO i = 1, zsize(1)
              clx3(i, j, k) = ux3(i, j - 1, k + 1)
              cly3(i, j, k) = uy3(i, j - 1, k + 1) * r1r2ratio
              clz3(i, j, k) = uz3(i, j - 1, k + 1) * r1r2ratio
            ENDDO
          ELSEIF (k.EQ.(nz - 1) / 2 + 1) THEN ! Middle z-point
            DO i = 1, zsize(1)
              clx3(i, j, k) = ux3(i, j - 1, k)
              cly3(i, j, k) = uy3(i, j - 1, k) * r1r2ratio
              clz3(i, j, k) = uz3(i, j - 1, k) * r1r2ratio
            ENDDO
          ELSEIF (k.EQ.nz) THEN ! Last z-point
            DO i = 1, zsize(1)
              clx3(i, j, k) = ux3(i, j - 1, k - 1)
              cly3(i, j, k) = uy3(i, j - 1, k - 1) * r1r2ratio
              clz3(i, j, k) = uz3(i, j - 1, k - 1) * r1r2ratio
            ENDDO
          ELSE ! General z-point
            IF (z.GT.0._mytype) THEN
              ya = y2 - dz
              DO i = 1, zsize(1)
                uu1 = ux3(i, j - 1, k - 1) &
                     + (ux3(i, j - 1, k) - ux3(i, j - 1, k - 1)) * (y1 - ya) / (y2 - ya)
                uv1 = uy3(i, j - 1, k - 1) &
                     + (uy3(i, j - 1, k) - uy3(i, j - 1, k - 1)) * (y1 - ya) / (y2 - ya)
                uw1 = uz3(i, j - 1, k - 1) &
                     + (uz3(i, j - 1, k) - uz3(i, j - 1, k - 1)) * (y1 - ya) / (y2 - ya)

                clx3(i, j, k) = uu1
                cly3(i, j, k) = uv1 * r1r2ratio
                clz3(i, j, k) = uw1 * r1r2ratio
              ENDDO
            ELSEIF (z.LT.0._mytype) THEN
              ya = y2 + dz
              DO i = 1, zsize(1)
                uu1 = ux3(i, j - 1, k + 1) &
                     + (ux3(i, j - 1, k + 1) - ux3(i, j - 1, k)) * (y1 - ya) / (ya - y2)
                uv1 = uy3(i, j - 1, k + 1) &
                     + (uy3(i, j - 1, k + 1) - uy3(i, j - 1, k)) * (y1 - ya) / (ya - y2)
                uw1 = uz3(i, j - 1, k + 1) &
                     + (uz3(i, j - 1, k + 1) - uz3(i, j - 1, k)) * (y1 - ya) / (ya - y2)

                clx3(i, j, k) = uu1
                cly3(i, j, k) = uv1 * r1r2ratio
                clz3(i, j, k) = uw1 * r1r2ratio
              ENDDO
            ELSE ! z = 0
               PRINT *, "Error, z=0 should not happen!"
               STOP
            ENDIF
         ENDIF !! End checking where we are in k

         ! Set fringe
         DO i = iph_fringe + 1, zsize(1)
            cly3(i, j, k) = 0._mytype
         ENDDO
        ENDIF !! End error check
      ENDDO !! End loop over k
   ENDIF !! End if (zend(2).eq.ny), i.e. last y boundary
  ENDIF !! End check that y is Dirichlet BC
ENDSUBROUTINE entrainment_bcy

!!--------------------------------------------------------------------
!!  SUBROUTINE: entrainment_bcz
!! DESCRIPTION: Implements entrainment boundary conditions on z
!!              boundary
!!        NOTE: In Y stencil, based on work of Ioannou Vasilis.
!!--------------------------------------------------------------------
SUBROUTINE entrainment_bcz(ux2, uy2, uz2, clx2, cly2, clz2)

  USE decomp_2d
  USE variables
  USE param
  
  IMPLICIT NONE

  REAL(mytype), DIMENSION(ysize(1), ysize(2), ysize(3)), INTENT(IN) :: ux2, uy2, uz2
  REAL(mytype), DIMENSION(ysize(1), ysize(2), ysize(3)) :: clx2, cly2, clz2

  REAL(mytype) :: uu1, uv1, uw1
  REAL(mytype) :: y, z, yc, zc, ya, x
  REAL(mytype) :: x1, x2, y1, y2, r1, r2, r1r2ratio
  REAL(mytype) :: l_fringe, xph_fringe
  INTEGER :: i, j, k, iph_fringe

  l_fringe = 0.1_mytype * xlx
  xph_fringe = xlx - l_fringe

  IF (nclz.EQ.2) THEN
     DO i = 1, ysize(1)
        x = (i + ystart(1) - 2) * dx
        IF (x.GT.xph_fringe) THEN
           EXIT
        ELSE
           iph_fringe = i
        ENDIF
     ENDDO

    yc = yly / 2._mytype
    zc = zlz / 2._mytype
    IF (ystart(3).EQ.1) THEN
      k = 1
      z = -zc
      DO j = 1, ysize(2)
        !y = (j - 1) * dy - yc
        y = (j + ystart(2) - 2) * dy - yc
        x2 = z
        y2 = y
        x1 = z + dz
        y1 = y2 * x1 / x2
        r1 = SQRT(x1**2 + y1**2)
        r2 = SQRT(x2**2 + y2**2)
        r1r2ratio = r1 / r2
        IF (r1.GT.r2) THEN
          PRINT *, "Bug1 error in entrainment_bcz"
          STOP
        ELSE
          IF (j.EQ.1) THEN ! First y point
            DO i = 1, ysize(1)
              clx2(i, j, k) = ux2(i, j + 1, k + 1)
              cly2(i, j, k) = uy2(i, j + 1, k + 1) * r1r2ratio
              clz2(i, j, k) = uz2(i, j + 1, k + 1) * r1r2ratio
            ENDDO
          ELSE IF(j.EQ.((ny - 1) / 2 + 1)) THEN ! Middle y point
            DO i = 1, ysize(1)
              clx2(i, j, k) = ux2(i, j, k + 1)
              cly2(i, j, k) = uy2(i, j, k + 1) * r1r2ratio
              clz2(i, j, k) = uz2(i, j, k + 1) * r1r2ratio
            ENDDO
          ELSE IF(j.EQ.ny) THEN ! Last y point
            DO i = 1, ysize(1)
              clx2(i, j, k) = ux2(i, j - 1, k + 1)
              cly2(i, j, k) = uy2(i, j - 1, k + 1) * r1r2ratio
              clz2(i, j, k) = uz2(i, j - 1, k + 1) * r1r2ratio
            ENDDO
          ELSE ! General y point
            IF(y.GT.0._mytype) THEN
              ya = y2 - dy
              DO i = 1, ysize(1)
                uu1 = ux2(i, j - 1, k + 1) &
                     + (ux2(i, j, k + 1) - ux2(i, j - 1, k + 1)) * (y1 - ya) / (y2 - ya)
                uv1 = uy2(i, j - 1, k + 1) &
                     + (uy2(i, j, k + 1) - uy2(i, j - 1, k + 1)) * (y1 - ya) / (y2 - ya)
                uw1 = uz2(i, j - 1, k + 1) &
                     + (uz2(i, j, k + 1) - uz2(i, j - 1, k + 1)) * (y1 - ya) / (y2 - ya)

                clx2(i, j, k) = uu1
                cly2(i, j, k) = uv1 * r1r2ratio 
                clz2(i, j, k) = uw1 * r1r2ratio
              ENDDO
            ELSE IF (y.LT.0._mytype) THEN
              ya = y2 + dy
              DO i = 1, ysize(1)
                uu1 = ux2(i, j + 1, k + 1) &
                     + (ux2(i, j + 1, k + 1) - ux2(i, j, k + 1)) * (y1 - ya) / (ya - y2)
                uv1 = uy2(i, j + 1, k + 1) &
                     + (uy2(i, j + 1, k + 1) - uy2(i, j, k + 1)) * (y1 - ya) / (ya - y2)
                uw1 = uz2(i, j + 1, k + 1) &
                     + (uz2(i, j + 1, k + 1) - uz2(i, j, k + 1)) * (y1 - ya) / (ya - y2)

                clx2(i, j, k) = uu1
                cly2(i, j, k) = uv1 * r1r2ratio
                clz2(i, j, k) = uw1 * r1r2ratio
              ENDDO
            ELSE
               PRINT *, "Error, y=0 should not happen!"
               STOP
            ENDIF
         ENDIF !! End checking where in y we are

         ! Set fringe
         DO i = iph_fringe + 1, ysize(1)
            clz2(i, j, k) = 0._mytype
         ENDDO
       END IF !! End error-check
      ENDDO !! End loop over j
    ENDIF !! End if (ystart(3).eq.1) i.e. first z boundary (k = 1)

    IF (yend(3).EQ.nz) THEN
      k = ysize(3)
      z = zc
      DO j = 1, ysize(2)
        y = (j + ystart(2) - 2) * dy - yc
        x2 = z
        y2 = y
        x1 = z - dz
        y1 = y2 * x1 / x2
        r1 = SQRT(x1**2 + y1**2)
        r2 = SQRT(x2**2 + y2**2)
        r1r2ratio = r1 / r2
        IF (r1.GT.r2) THEN
          PRINT *, "Bug2 in entrainment_bcz"
          STOP
        ELSE
          IF (j.EQ.1) THEN ! First y point
            DO i = 1, ysize(1)
              clx2(i, j, k) = ux2(i, j + 1, k - 1)
              cly2(i, j, k) = uy2(i, j + 1, k - 1) * r1r2ratio
              clz2(i, j, k) = uz2(i, j + 1, k - 1) * r1r2ratio
            ENDDO
          ELSEIF (j.EQ.((ny - 1) / 2 + 1)) THEN ! Mid y point
            DO i = 1, ysize(1)
              clx2(i, j, k) = ux2(i, j, k - 1)
              cly2(i, j, k) = uy2(i, j, k - 1) * r1r2ratio
              clz2(i, j, k) = uz2(i, j, k - 1) * r1r2ratio
            ENDDO
          ELSEIF (j.EQ.ny) THEN ! Last y point
            DO i = 1, ysize(1)
              clx2(i, j, k) = ux2(i, j - 1, k - 1)
              cly2(i, j, k) = uy2(i, j - 1, k - 1) * r1r2ratio
              clz2(i, j, k) = uz2(i, j - 1, k - 1) * r1r2ratio
            ENDDO
          ELSE ! General y point
            IF (y.GT.0._mytype) THEN
              ya = y2 - dy
              DO i = 1, ysize(1)
                uu1 = ux2(i, j - 1, k - 1) &
                     + (ux2(i, j, k - 1) - ux2(i, j - 1, k - 1)) * (y1 - ya) / (y2 - ya)
                uv1 = uy2(i, j - 1, k - 1) &
                     + (uy2(i, j, k - 1) - uy2(i, j - 1, k - 1)) * (y1 - ya) / (y2 - ya)
                uw1 = uz2(i, j - 1, k - 1) &
                     + (uz2(i, j, k - 1) - uz2(i, j - 1, k - 1)) * (y1 - ya) / (y2 - ya)

                clx2(i, j, k) = uu1
                cly2(i, j, k) = uv1 * r1r2ratio
                clz2(i, j, k) = uw1 * r1r2ratio
              ENDDO
            ELSE IF (y.LT.0._mytype) THEN
              ya = y2 + dy
              DO i = 1, ysize(1)
                uu1 = ux2(i, j + 1, k - 1) &
                     + (ux2(i, j + 1, k - 1) - ux2(i, j, k - 1)) * (y1 - ya) / (ya - y2)
                uv1 = uy2(i, j + 1, k - 1) &
                     + (uy2(i, j + 1, k - 1) - uy2(i, j, k - 1)) * (y1 - ya) / (ya - y2)
                uw1 = uz2(i, j + 1, k - 1) &
                     + (uz2(i, j + 1, k - 1) - uz2(i, j, k - 1)) * (y1 - ya) / (ya - y2)

                clx2(i, j, k) = uu1
                cly2(i, j, k) = uv1 * r1r2ratio
                clz2(i, j, k) = uw1 * r1r2ratio
              ENDDO
            ELSE
               PRINT *, "Error, y=0 should not happen!"
               STOP
            ENDIF
         ENDIF !! End checking where in y we are

         ! Set fringe
         DO i = iph_fringe + 1, ysize(1)
            clz2(i, j, k) = 0._mytype
         ENDDO
        ENDIF !! End error-check
      ENDDO !! End loop over j
   ENDIF !! End if (yend(3).eq.nz) i.e. the end of z (k = nz)
  ENDIF !! End check that z is Dirichlet BC
  
ENDSUBROUTINE entrainment_bcz

!!--------------------------------------------------------------------
!!  SUBROUTINE: fringe_bcx
!! DESCRIPTION: Implements fringe boundary conditions on x.
!!        NOTE: X-PENCIL. Based on work of Ioannou Vasilis.
!!--------------------------------------------------------------------
SUBROUTINE fringe_bcx(ta1, tb1, tc1, ux1, uy1, uz1, rho1) !, bc1, bcn)

  USE MPI
  USE decomp_2d
  USE variables
  USE param

  IMPLICIT NONE

  REAL(mytype), DIMENSION(xsize(1), xsize(2), xsize(3)) :: ta1, tb1, tc1
  REAL(mytype), DIMENSION(xsize(1), xsize(2), xsize(3)), INTENT(IN) :: ux1, uy1, uz1, rho1
  ! INTEGER, INTENT(IN) :: bc1, bcn
  
  REAL(mytype) :: ucf, f_fringe, utarget
  REAL(mytype) :: gauss, g_umax, g_rext, g_rext2
  REAL(mytype) :: l_fringe, xph_fringe
  REAL(mytype) :: x, y, z, yc, zc, r2, y1, y2, y3, r1, r3
  INTEGER :: i, j, k, iph_fringe, ctr, ierr

  l_fringe = 0.1_mytype * xlx

  !! Gaussian forcing
  ucf = 0.1_mytype * u1 * (PI * 0.5_mytype**2) / (yly * zlz)
  g_rext = 1.5_mytype / 2.14_mytype
  g_rext2 = g_rext**2
  
  g_umax = 1._mytype

  yc = yly / 2._mytype
  zc = zlz / 2._mytype

  ! !! Xstart
  ! IF (bc1.EQ.1) THEN
  ! ENDIF !! End XSTART BC
  
  !! Xend
  ! IF (bcn.EQ.1) THEN
    xph_fringe = xlx - l_fringe
    iph_fringe = CEILING(xph_fringe * DBLE(nx - 1) / xlx)

    DO k = 1, xsize(3)
      z = DBLE(k + xstart(3) - 2) * dz - zc
      DO j = 1, xsize(2)
        y = DBLE(j + xstart(2) - 2) * dy - yc

        r2 = y**2 + z**2
        gauss = bxxn_scale * (g_umax * EXP(-r2 / g_rext2) + ucf)
        utarget = gauss

        utarget = outflux / (yly * zlz)
        
        DO i = iph_fringe, xsize(1)
          x = DBLE(i + xstart(1) - 2) * dx
          f_fringe = COS(((x - xph_fringe) / l_fringe) * PI / 2._mytype)
          f_fringe = f_fringe**2
          ! f_fringe = 1._mytype - SIN(((x - xph_fringe) / l_fringe) * (2._mytype * PI / 4._mytype))
          ! f_fringe = COS(((x - xph_fringe) / l_fringe) * (PI / 2._mytype)) &
          !      * (1._mytype - SIN(((x - xph_fringe) / l_fringe) * (PI / 2._mytype)))

          ta1(i, j, k) = f_fringe * ta1(i, j, k) + rho1(i, j, k) * (utarget - ux1(i, j, k)) &
               * (1._mytype - f_fringe)
          tb1(i, j, k) = f_fringe * tb1(i, j, k) + rho1(i, j, k) * (0._mytype - uy1(i, j, k)) &
               * (1._mytype - f_fringe)
          tc1(i, j, k) = f_fringe * tc1(i, j, k) + rho1(i, j, k) * (0._mytype - uz1(i, j, k)) &
               * (1._mytype - f_fringe)
        ENDDO !! End loop over i
      ENDDO !! End loop over j
    ENDDO !! End loop over k
  ! ENDIF !! End XEND BC
  
ENDSUBROUTINE fringe_bcx

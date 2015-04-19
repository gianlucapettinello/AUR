#!/usr/bin/bash

. "${HOME}/.config/clean-chroot-manager.conf"


if [[ -z "${PKGDIR}" ]]; then
  PKGDIR="${AURDIR}"
fi

LOGFILE="${PKGDIR}/ccm.log"
TMPDIR="/mnt/CACHE/AUR"
AURHLP="/usr/bin/cower -ddf"
CCM_BLD_64="sudo /usr/bin/ccm64 S"
CCM_BLD_32="sudo /usr/bin/ccm32 S"
CCM_CLR_64="sudo /usr/bin/ccm64 d"
CCM_CLR_32="sudo /usr/bin/ccm32 d"
CCM_UPD_64="sudo /usr/bin/ccm64 u"
CCM_UPD_32="sudo /usr/bin/ccm32 u"

TESTER="$(whoami)"

totee()
{
  if [[ -z "${LOGONLY}" ]]; then
    tee -a "${LOGFILE}"
  else
    tee -a "${LOGFILE}" &> /dev/null
  fi
}

smsg()
{
  # Make sure to use an empty LOGONLY so this message is
  # always displayed.
  echo "[STATUS] ==> $1 - x${arch} : $2" | LOGONLY="" totee
}

msg()
{
  echo "==> $1" | totee
}

msg2()
{
  echo "  -> $1" | totee
}

setup_test_env()
{
  msg "creating temp directories..."
  if [[ ! -d "${TMPDIR}" ]]; then
    mkdir "${TMPDIR}"
  fi
  if [[ "x${arch}" == "x64" ]]; then
    $CCM_CLD_64 | totee
    $CCM_UPD_64 | totee
    CHROOT_PATH="${CHROOTPATH64}/${TESTER}"
  else
    $CCM_CLD_32 | totee
    $CCM_UPD_32 | totee
    CHROOT_PATH="${CHROOTPATH32}/${TESTER}"
  fi
}

__ccm_build()
{
  if [[ "x${arch}" == "x64" ]]; then
    $CCM_BLD_64 | totee
  elif [[ "x${arch}" == "x32" ]]; then
    $CCM_BLD_32 | totee
  fi
  return "${PIPESTATUS[0]}"
}

install_dep()
{
  msg "downloading dependecies... $1"
  cd "${TMPDIR}"
  $AURHLP $1 | totee
  cd "${TMPDIR}/$1"
  __ccm_build
  cd "${PKGDIR}"
}

ccm_build()
{
  cp -Rf "${PKGDIR}/$1" "${TMPDIR}"
  cd "${TMPDIR}/$1"

  smsg "$1" "building started"
  if __ccm_build ; then
    smsg "$1" "building succeded"
  else
    smsg "$1" "building failed"
  fi
}

secure_copy()
{
  msg "waiting for $2 to be created..."
  until [[ -e "$2" ]]; do
    sleep 1
  done
  msg "found $2: copying files..." 
  /usr/bin/cp -rvT "$1" "$2" | totee
}

test_vtk_git()
{
  setup_test_env
  CH_EXT_DIR="${CHROOT_PATH}/build/vtk-git/src/ExternalData"
  EXT_DIR="/mnt/CACHE/MAKEPKG/sources/VTKExternalData"
  msg "testing vtk-git..."
  install_dep "netcdf-cxx-legacy"
  msg "Copying External Data..."
  secure_copy "${EXT_DIR}" "${CH_EXT_DIR}" &
  ccm_build "vtk-git"
  msg "saving external data..."
  cp -rvT "${CH_EXT_DIR}" "${EXT_DIR}" | totee
}

test_libsnl_svn()
{
  setup_test_env
  msg "testing libsnl-svn..."

  ccm_build "libsnl-svn"
}

test_calculix()
{
  setup_test_env
  msg "testing calculix..."

  install_dep spooles
  test_libsnl_svn

  ccm_build "calculix"
}

test_calculix_doc()
{
  setup_test_env
  msg "testing calculix-doc..."

  test_calculix

  ccm_build "calculix-doc"
}

test_pk2_la_svn()
{
  setup_test_env
  msg "testing pk2-la-svn..."

  install_dep python2-pyusb

  ccm_build "pk2-la-svn"
}

test_lxnstack()
{
  setup_test_env
  msg "testing lxnstack..."

  ccm_build "lxnstack"
}

if [[ "x$2" == "x32" ]]; then
  msg "building in i686 env"
  arch="32"
else
  msg "buinding in x86_64 env"
  arch="64"
fi

LOGFILE="${PKGDIR}/ccm${arch}.log"

msg "clearing log file..."
rm ${LOGFILE}

case $1 in
  vtk-git)
    test_vtk_git
    ;;
  calculix)
    test_calculix
    ;;
  calculix-doc)
    test_calculix_doc
    ;;
  libsnl-svn)
    test_libsnl_svn
    ;;
  pk2-la-svn)
    test_pk2_la_svn
    ;;
  lxnstack)
    test_lxnstack
    ;;
  all)
    test_calculix_doc
    test_vtk_git
    test_lxstack
    test_pk2_la_svn
    ;;
  *)
    echo "Unkown package '$1'"
    ;;
esac

# vim: ft=sh syn=sh
# vim: set ts=2 sw=2 et:


#!/bin/bash
# Takes snapshot of the linux kernel and (optionally) patches it from kernel.org
# Builds it using a selected .config file.
# This scripts automates half of the offsite kernel building process,
# and it's intended to work along with linux_MakeExport.sh.
# Usage: ./script <tag/commit> [<config_path>]
# LINUX_GITDIR env var should be set to point to a Linux git repo. If not, LINUX_GITDIR is set to curr dir.
if test $# -lt 1; then
  echo "invalid number of parameters.abort" >&2
  exit 1
fi
if test -z ${LINUX_GITDIR} ; then
  linuxdir="./"
else
  linuxdir=${LINUX_GITDIR}
fi
tmpdir=$(mktemp -d )
mkdir ${tmpdir}/${1}
#decompose kernel version in case of vX.Y.Z into vX.Y(from git) and patch vX.Y.Z from kernel.org
#Supports v3.x and v4.x kernels ONLY. unexpected results for anything else.
echo "$1" | grep -Eq "v[0-9]\.[0-9]+\.[0-9]+$"
if test $? -eq 0 ; then
  git rev-parse ${1} >/dev/null 2>&1
  if test $? -ne 0 ; then
    #not a git tag, so let's find it on kernel.org
    #here get ver_dir, ver_num and ver_base from vX.Y.Z
    kernelhttp="https://cdn.kernel.org/pub/linux/kernel"
    ver_base="$(dirname $(echo ${1}|tr . /)| tr / .)"
    ver_dir="$(echo ${1} | sed 's#\..*#.x#')"
    ver_num="$(echo ${1}|sed 's/^v//')"
    patch_name="patch-${ver_num}.xz"
    echo "Fetching patch from ${kernelhttp}/${ver_dir}/${patch_name}"
    wget -P ${tmpdir} ${kernelhttp}/${ver_dir}/${patch_name} >/dev/null
    if test $? -ne 0 ; then
      echo "patch file not found. abort" >&2
      rm ${tmpdir} -rf
      exit 1
    fi
  else
    ver_base=${1}
  fi
else
  ver_base=${1}
fi
git -C ${linuxdir} archive ${ver_base} 2>/dev/null | tar Cx ${tmpdir}/${1} >/dev/null 2>&1
if test $? -ne 0 ; then
  echo "commit/tag not valid. abort" >&2
  rm ${tmpdir} -rf
  exit 1
fi
#detect and install patch
if test ! -z ${patch_name} ; then
  cd ${tmpdir}/${1}
  xzcat ../${patch_name} |patch -p1
  cd -
fi
if [[ $# -gt 1 && -f "$2" ]] ; then
  echo "Copying file ${2} as .config"
  cp ${2} ${tmpdir}/${1}/.config
fi
echo "go to ${tmpdir}.bye"
exit 0

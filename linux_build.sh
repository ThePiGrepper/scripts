#!/bin/bash
# Takes a tag snapshot of the linux kernel and (optionally) patches it from kernel.org(TODO)
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
git -C ${linuxdir} archive ${1} 2>/dev/null | tar Cx ${tmpdir}/${1} >/dev/null 2>&1
if test $? -ne 0 ; then
  echo "commit/tag not valid. abort" >&2
  rm ${tmpdir} -rf
  exit 1
fi
if [[ $# -gt 1 && -f "$2" ]] ; then
  echo "Copying file ${2} as .config"
  cp ${2} ${tmpdir}/${1}/.config
fi
exit 0

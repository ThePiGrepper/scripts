#!/bin/bash
# MUST RUN from linux build basedir
# Usage: ./script <dest_ip> [<suffix>]
if test $# -lt 1 ; then
  echo "not enough arguments. abort"
  exit 1
fi
dest_ip=${1}
tmpdir=$(mktemp -d)
echo "Temp dir $tmpdir created..."
if test $# -gt 1 ; then
  suffix=${2}
else
  suffix=$(basename ${tmpdir}|sed 's/tmp\.//')
fi
sudo make INSTALL_MOD_PATH=${tmpdir} modules_install
cp arch/x86/boot/bzImage ${tmpdir}/vmlinuz-linux-${suffix}
#Generate installation script
echo -e "#!/bin/bash
if [[ \$EUID > 0 ]]; then
  echo 'Run as root.abort'
  exit 1
else
  srcdir=\"\$( cd \"\$( dirname \"\${BASH_SOURCE[0]}\" )\" && pwd )\"
  cd \${srcdir}
  tar xf ${suffix}.tar
  rsync -azP lib/ /lib/
  cp vmlinuz-linux-${suffix} /boot/
  #mkinitcpio -k 4.16.0-ARCH -g /boot/initramfs-linux-${suffix}.img
fi" > ${tmpdir}/INSTALL.sh
chmod +x ${tmpdir}/INSTALL.sh
sudo tar cpf ${tmpdir}/${suffix}.tar -C ${tmpdir} lib --remove-files
#once installed on the temp dir. send all files to the destination machine
#NOTE: ssh works using the SAME userID!!
rsync -aPz -e 'ssh' ${tmpdir} ${dest_ip}:/tmp
#cleanup
sudo rm -rf ${tmpdir}
exit 0

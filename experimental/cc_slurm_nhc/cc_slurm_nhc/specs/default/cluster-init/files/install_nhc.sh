#!/bin/bash

# Tagged Version 1.4.2 failed the tests (lbnl_file.nhc)

TMPDIR=/tmp
#TAR_FILE=$CYCLECLOUD_SPEC_PATH/files/lbnl-nhc-01-16-2022.tar.gz
TAR_FILE=$CYCLECLOUD_SPEC_PATH/files/


function get_source() {

   if [[ -f $TAR_FILE ]]
   then
      tar xvf $TAR_FILE
   else
      git clone https://github.com/mej/nhc.git
   fi
}


function install_from_source() {

   if ! [[ -f  /usr/bin/nfc ]] && ! [[ -d /etc/default/nhc ]]
   then
      cd $TMPDIR
      get_source 
      cd nhc
      ./autogen.sh
      ./configure --prefix=/usr --sysconfdir=/etc --libexecdir=/usr/lib
      make test
      make install

      rm -rf $TMPDIR/nhc
    else
      echo "Warning: Did not install NHC (looks like it already has been installed)"
   fi

}

install_from_source

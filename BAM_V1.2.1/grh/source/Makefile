#
#  $Author: pkubota $
#  $Date: 2007/10/10 20:28:03 $
#  $Revision: 1.4 $
#
# $Id: Makefile,v 1.4 2007/10/10 20:28:03 pkubota Exp $
#
SHELL=/bin/sh
#
# Makefile for Grid History Pos-Proccessing output global model
#
# Targets are the suffixes of the system-specific makefiles in
# the makefiles/ directory.
# For example, to build PosGrib for Solaris, give the command
#
#   make solaris
#
# This builds an intermediate library in the util/ directory,
# then builds the nedit and nc executables in the source/ directory.
#
MAKE=make
PATH2=/mnt/beegfs/carlos.bastarz/cfbastarz.tmp/BAM_V1.2.1/grh/exec

all:
	@echo "Please specify target:"
	@echo "(For example, type \"make linux\" for a Linux system.)"
	@(cd  makefiles && ls -C Makefile* | sed -e 's/Makefile.//g')

.DEFAULT:
	@- (cd .; if [ -f makefiles/Makefile.$@ -a ! -f ./Makefile.$@ ];\
	   then ln -fs makefiles/Makefile.$@ Makefile.$@; fi)

	(cd .;$(MAKE) -f Makefile.$@)
	(mv PostGridHistory $(PATH2)/PostGridHistory)
	(rm  -f Makefile.$@ )

# We need a "dev-all" target that builds the docs plus binaries, but
# that doesn't work since we require the user to specify the target.  More
# thought is needed

clean:
	@echo "$(MAKE)"
	(cd .;$(MAKE) -f Makefile.common clean)

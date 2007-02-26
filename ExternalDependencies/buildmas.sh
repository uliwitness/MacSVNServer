#!/bin/bash
#============================================================================================================================
# MAS Build Script - compiles the subversion and apache server inside the MAS application bundle
#============================================================================================================================
# HOW TO RUN THIS FILE: (TextMate users can press Cmd+R to run this file!)
# ------------------------------------------------------------------------
# you have to make this file executable before you can run it. simply double clicking won't work.
# open the Terminal located in /applications/utilities/ and enter
#   cd ~/macsvnserver/ExternalDependencies/ (change the path to elsewhere if you extracted MAS to a different location)
# then enter
#   chmod +x buildmas.sh
# now you can double click this file in the Finder to run it
#============================================================================================================================

# Get full path of folder containing this script:
WORKING_DIR="`dirname $0`"	# This may give a relative path.
cd "$WORKING_DIR"
WORKING_DIR="`pwd`"			# pwd always gives absolute paths.


# log to file, and display on stdout at the same time
# taken from http://www.travishartwell.net/blog/2006/08/19_2220
# ---------------------------------------------------------------------------------------------------------------------------
OUTPUT_LOG="$WORKING_DIR/build.log"
OUTPUT_PIPE="$WORKING_DIR/build.pipe"

if [ ! -e $OUTPUT_PIPE ]; then mkfifo $OUTPUT_PIPE; fi
if [ -e $OUTPUT_LOG ]; then rm $OUTPUT_LOG; fi
exec 3>&1 4>&2
tee $OUTPUT_LOG < $OUTPUT_PIPE >&3 &
tpid=$!
exec > $OUTPUT_PIPE 2>&1

# on any exit command, return the stdout & stderr to normal, and remove the temporary pipe file
trap 'exec 1>&3 3>&- 2>&4 4>&-; wait $tpid; rm $OUTPUT_PIPE;' EXIT
trap 'die "@ script terminated"' INT TERM  #clean up if the user presses ^c
# ---------------------------------------------------------------------------------------------------------------------------

die()
{
	#display the error message
	echo "${1}"
	#exit with error code 1, unless parameter 2 has been supplied which is the error code to use
	exit ${2:-1}
}

clear 2>/dev/null #errors when running from TextMate
echo "==============================================================================="
echo "MAS subversion/apache build script"
echo "==============================================================================="

echo "configuration:"
echo "-------------------------------------------------------------------------------"

# quiet mode is default. we'll override this with -v or --verbose argument to this script (TODO)
# '--quiet' is universally accepted in ./configure and make as substitute to -q and -s accordingly.
QUIET="--quiet"
echo "@ quiet mode is on. override with -v or --verbose"
echo "@ working from '$WORKING_DIR'"

# get the location of the application bundle outputted by the XCode build
MAS_APP="$WORKING_DIR/../Application/build/Release/MAS.app"
MAS_PREFIX="$MAS_APP/Contents/Resources/MAS"
echo "@ using MAS.app from '$MAS_APP'"


# has the user built the XCode project first?
if ! [ -d "$WORKING_DIR/../Application/build/Release/MAS.app" ]
then
	echo ""
	echo "! the XCode project must be built first"
	die "  please open 'macsvnserver/Application/MAS.xcodeproj' and click the Build button"
fi

echo ""
echo "==============================================================================="
echo "[1] source code preperation"
echo "==============================================================================="

# location the source code will be unpacked and compiled from
SOURCES_DIR="`echo $WORKING_DIR`/Sources/"

# Have a sources folder? Use it, otherwise extract stuff from
# the Archives folder into a new Sources folder:
if [ -d "$SOURCES_DIR" ]
then
	echo "@ using existing Sources folder"
	echo "  ($SOURCES_DIR)"
	cd $SOURCES_DIR
else
	echo "@ source code not present, unpacking from archives..."
	
	echo "-------------------------------------------------------------------------------"
	echo "* checking Archives folder for correct contents"
	
	ISERROR=false
	#!## locate expat source code archive
	#!#EXPAT_ARCHIVE="`find Archives -name 'expat-*.tar.gz' -print -maxdepth 1 2>/dev/null`"
	#!#if ! [ -n "$EXPAT_ARCHIVE" ]; then echo "! expat source code archive is missing"; echo "  expecting 'macsvnserver/ExternalDependencies/Archives/expat-?.?.?.tar.gz'"; ISERROR=true; fi
	# locate libxml source code archive
	LIBXML_ARCHIVE="`find Archives -name 'libxml2-*.tar.gz' -print -maxdepth 1 2>/dev/null`"
	if ! [ -n "$LIBXML_ARCHIVE" ]; then echo "! libxml source code archive is missing"; echo "  expecting 'macsvnserver/ExternalDependencies/Archives/libxml2-?.?.?.tar.gz'"; ISERROR=true; fi
	# locate gettext source code archive
	GETTEXT_ARCHIVE="`find Archives -name 'gettext-*.tar.gz' -print -maxdepth 1 2>/dev/null`"
	if ! [ -n "$GETTEXT_ARCHIVE" ]; then echo "! gettext source code archive is missing"; echo "  expecting 'macsvnserver/ExternalDependencies/Archives/gettext-?.?.?.tar.gz'"; ISERROR=true; fi
	# locate neon source code archive
	NEON_ARCHIVE="`find Archives -name 'neon-*.tar.gz' -print -maxdepth 1 2>/dev/null`"
	if ! [ -n "$NEON_ARCHIVE" ]; then echo "! neon source code archive is missing"; echo "  expecting 'macsvnserver/ExternalDependencies/Archives/neon-?.?.?.tar.gz'"; ISERROR=true; fi
	# locate apr source code archive
	APR_ARCHIVE="`find Archives -regex '.*/apr-[^u]*\.tar\.gz' -print -maxdepth 1 2>/dev/null`"
	if ! [ -n "$APR_ARCHIVE" ]; then echo "! apr source code archive is missing"; echo "  expecting 'macsvnserver/ExternalDependencies/Archives/apr-?.?.?.tar.gz'"; ISERROR=true; fi
	# locate apr-util source code archive
	APRUTIL_ARCHIVE="`find Archives -regex '.*/apr-util-.*\.tar\.gz' -print -maxdepth 1 2>/dev/null`"
	if ! [ -n "$APRUTIL_ARCHIVE" ]; then echo "! apr-util source code archive is missing"; echo "  expecting 'macsvnserver/ExternalDependencies/Archives/apr-util-?.?.?.tar.gz'"; ISERROR=true; fi
	# locate apache source code archive
	HTTPD_ARCHIVE="`find Archives -name 'httpd-*.tar.gz' -print -maxdepth 1 2>/dev/null`"
	if ! [ -n "$HTTPD_ARCHIVE" ]; then echo "! Apache source code archive is missing"; echo "  expecting 'macsvnserver/ExternalDependencies/Archives/httpd-?.?.?.tar.gz'"; ISERROR=true; fi
	# locate SubVersioN source code archive
	SVN_ARCHIVE="`find Archives -name 'subversion-*.tar.gz' -print -maxdepth 1 2>/dev/null`"
	if ! [ -n "$SVN_ARCHIVE" ]; then echo "! SVN source code archive is missing"; echo "  expecting 'macsvnserver/ExternalDependencies/Archives/subversion-?.?.?.tar.gz'"; ISERROR=true; fi
	
	# were any of the archives missing?
	if [ "$ISERROR" = "true" ]; then
		echo ""
		die "! some source code archives are missing. please download ExternalDependencies.zip from the MAS website and extract it into the Archives folder"
	else
		echo "@ all archives are present and correct"
	fi
	
	echo "-------------------------------------------------------------------------------"
	echo "extracting archives"
	echo "-------------------------------------------------------------------------------"
	
	mkdir Sources
	cd $SOURCES_DIR

	# extract the archives into the Sources directory
	#!#echo "* extracting $EXPAT_ARCHIVE..."
	#!#tar -xzf "../$EXPAT_ARCHIVE"
	echo "* extracting $LIBXML_ARCHIVE..."
	tar -xzf "../$LIBXML_ARCHIVE"
	echo "* extracting $GETTEXT_ARCHIVE..."
	tar -xzf "../$GETTEXT_ARCHIVE"
	echo "* extracting $NEON_ARCHIVE..."
	tar -xzf "../$NEON_ARCHIVE"
	echo "* extracting $APR_ARCHIVE..."
	tar -xzf "../$APR_ARCHIVE"
	echo "* extracting $APRUTIL_ARCHIVE..."
	tar -xzf "../$APRUTIL_ARCHIVE"
	echo "* extracting $HTTPD_ARCHIVE..."
	tar -xzf "../$HTTPD_ARCHIVE"
	echo "* extracting $SVN_ARCHIVE..."
	tar -xzf "../$SVN_ARCHIVE"
	
	echo "-------------------------------------------------------------------------------"
	echo "renaming source folders to exclude version number"
	echo "-------------------------------------------------------------------------------"
	
	#!EXPAT_FOLDER="`find . -name 'expat-*[^z]' -print -maxdepth 1`"
	LIBXML_FOLDER="`find . -name 'libxml2-*[^z]' -print -maxdepth 1`"
	GETTEXT_FOLDER="`find . -name 'gettext-*[^z]' -print -maxdepth 1`"
	NEON_FOLDER="`find . -name 'neon-*[^z]' -print -maxdepth 1`"
	APR_FOLDER="`find . -regex '.*/apr-[^u]*' -print -maxdepth 1`"
	APRUTIL_FOLDER="`find . -name 'apr-util-*[^z]' -print -maxdepth 1`"
	HTTPD_FOLDER="`find . -name 'httpd-*[^z]' -print -maxdepth 1`"
	SVN_FOLDER="`find . -name 'subversion-*[^z]' -print -maxdepth 1`"
	
	#!#echo "* $EXPAT_FOLDER > ./expat"
	#!#mv "$EXPAT_FOLDER" ./expat
	echo "* $LIBXML_FOLDER > ./libxml2"
	mv "$LIBXML_FOLDER" ./libxml2
	echo "* $GETTEXT_FOLDER > ./gettext"
	mv "$GETTEXT_FOLDER" ./gettext
	echo "* $NEON_FOLDER > ./neon"
	mv "$NEON_FOLDER" ./neon
	echo "* $APR_FOLDER > ./apr"
	mv "$APR_FOLDER" ./apr
	echo "* $APRUTIL_FOLDER > ./apr-util"
	mv "$APRUTIL_FOLDER" ./apr-util
	echo "* $HTTPD_FOLDER > ./httpd"
	mv "$HTTPD_FOLDER" ./httpd
	echo "* $SVN_FOLDER > ./subversion"
	mv "$SVN_FOLDER" ./subversion
	
	echo "-------------------------------------------------------------------------------"
	echo "creating symlinks to packages SVN includes"
	echo "-------------------------------------------------------------------------------"
	
	echo -n "* "; ln -sv ../apr subversion/apr
	echo -n "* "; ln -sv ../apr-util subversion/apr-util
	echo -n "* "; ln -sv ../neon subversion/neon
fi

# the following needs to be before any builds so it doesn't
# clean away the apr, apr-util and neon builds we just did.
echo "-------------------------------------------------------------------------------"
echo "cleaning up previous subversion build information"
echo "-------------------------------------------------------------------------------"
cd subversion
make $QUIET clean 2>/dev/null  # don't print the "no rule to make 'clean'" error
make $QUIET distclean 2>/dev/null
echo "@ preperation is complete"



echo ""
echo "==============================================================================="
echo "[2] building libxml2"
echo "==============================================================================="

#!#CFLAGS="-O -g -arch i386 -arch ppc -isysroot /Developer/SDKs/MacOSX10.4u.sdk"
CFLAGS="-O -g  -isysroot /Developer/SDKs/MacOSX10.4u.sdk -arch ppc -arch i386"
export CFLAGS
#!#LDFLAGS="-Wl,-syslibroot,/Developer/SDKs/MacOSX10.4u.sdk"
#!#export LDFLAGS

cd ../libxml2
echo "configuring libxml2"
echo "-------------------------------------------------------------------------------"
./configure $QUIET --prefix=$MAS_PREFIX --disable-dependency-tracking
if [ $? -gt 0 ]; then die "! configuring of libxml2 failed" 21; fi

echo "-------------------------------------------------------------------------------"
echo "compiling libxml2"
echo "-------------------------------------------------------------------------------"
make $QUIET clean 2>/dev/null
make $QUIET
if [ $? -gt 0 ]; then die "! compiling of libxml2 failed" 22; fi

echo "-------------------------------------------------------------------------------"
echo "installing libxml2"
echo "-------------------------------------------------------------------------------"
make $QUIET install
if [ $? -gt 0 ]; then die "! installing of libxml2 failed" 23; fi
echo "@ libxml2 was built"



echo ""
echo "==============================================================================="
echo "[3] building gettext"
echo "==============================================================================="
echo "configuring gettext"
echo "-------------------------------------------------------------------------------"
cd ../gettext
./configure $QUIET --prefix=$MAS_PREFIX --enable-csharp=no
if [ $? -gt 0 ]; then die "! configuring of gettext failed" 31; fi

echo "-------------------------------------------------------------------------------"
echo "compiling gettext"
echo "-------------------------------------------------------------------------------"
make $QUIET
if [ $? -gt 0 ]; then die "! building of gettext failed" 32; fi

echo "-------------------------------------------------------------------------------"
echo "installing gettext"
echo "-------------------------------------------------------------------------------"
make $QUIET install
if [ $? -gt 0 ]; then die "! installing of gettext failed" 33; fi
echo "@ gettext was built"



echo ""
echo "==============================================================================="
echo "[4] building neon"
echo "==============================================================================="
echo "configuring neon"
echo "-------------------------------------------------------------------------------"
cd ../neon
./configure $QUIET --prefix=$MAS_PREFIX --with-libs=${MAS_PREFIX}:/usr --with-apxs=${MAS_PREFIX}/bin/apxs
if [ $? -gt 0 ]; then die "! configuring of neon failed" 41; fi
	
echo "-------------------------------------------------------------------------------"
echo "compiling neon"
echo "-------------------------------------------------------------------------------"
make $QUIET
if [ $? -gt 0 ]; then die "! building of neon failed" 42; fi
	
echo "-------------------------------------------------------------------------------"
echo "installing neon"
echo "-------------------------------------------------------------------------------"
make $QUIET install
if [ $? -gt 0 ]; then die "! installing of neon failed" 43; fi
echo "@ neon was built"



echo ""
echo "==============================================================================="
echo "[5] building Apache Portable Runtime"
echo "==============================================================================="
echo "configuring apr"
echo "-------------------------------------------------------------------------------"
cd ../apr
./configure $QUIET --prefix=$MAS_PREFIX --with-libs=${MAS_PREFIX}:/usr
if [ $? -gt 0 ]; then die "! configuring of apr failed" 51; fi

echo "-------------------------------------------------------------------------------"
echo "compiling apr"
echo "-------------------------------------------------------------------------------"
make $QUIET
if [ $? -gt 0 ]; then die "! building of apr failed" 52; fi

echo "-------------------------------------------------------------------------------"
echo "installing apr"
echo "-------------------------------------------------------------------------------"
make $QUIET install
if [ $? -gt 0 ]; then die "! installing of apr failed" 53; fi
echo "@ apr was built"



echo ""
echo "==============================================================================="
echo "[6] building apr-util"
echo "==============================================================================="
echo "configuring apr-util"
echo "-------------------------------------------------------------------------------"
cd ../apr-util
./configure $QUIET --prefix=$MAS_PREFIX --with-libs=${MAS_PREFIX}:/usr --with-apr=$MAS_PREFIX --with-iconv=/usr
if [ $? -gt 0 ]; then die "! configuring of apr-util failed" 61; fi

echo "-------------------------------------------------------------------------------"
echo "compiling apr-util"
echo "-------------------------------------------------------------------------------"
make $QUIET
if [ $? -gt 0 ]; then die "! building of apr-util failed" 62; fi
	
echo "-------------------------------------------------------------------------------"
echo "installing apr-util"
echo "-------------------------------------------------------------------------------"
make $QUIET install
if [ $? -gt 0 ]; then die "! installing of apr-util failed" 63; fi
echo "@ apr-util was built"



echo ""
echo "==============================================================================="
echo "[7] building Apache 2"
echo "==============================================================================="
echo "configuring httpd"
echo "-------------------------------------------------------------------------------"
cd ../httpd
make $QUIET clean 2>/dev/null
make $QUIET distclean 2>/dev/null
./configure $QUIET --prefix=$MAS_PREFIX --with-libs=${MAS_PREFIX}:/usr --with-apr=$MAS_PREFIX --with-apr-util=$MAS_PREFIX --enable-so --enable-dav-fs --enable-dav-lock --enable-dav --enable-static-htpasswd --enable-static-support --disable-authn-dbd --without-sqlite --with-port=8800
if [ $? -gt 0 ]; then die "! configuring of httpd failed" 71; fi

echo "-------------------------------------------------------------------------------"
echo "compiling httpd"
echo "-------------------------------------------------------------------------------"
make $QUIET
if [ $? -gt 0 ]; then die "! building of httpd failed" 72; fi

echo "-------------------------------------------------------------------------------"
echo "installing httpd"
echo "-------------------------------------------------------------------------------"
make $QUIET install
if [ $? -gt 0 ]; then die "! installing of httpd failed" 73; fi
echo "@ httpd was built"



echo ""
echo "==============================================================================="
echo "[8] building subversion"
echo "==============================================================================="
echo "configuring subversion"
echo "-------------------------------------------------------------------------------"
cd ../subversion
./configure $QUIET --prefix=$MAS_PREFIX --with-libs=${MAS_PREFIX}:/usr --with-apr=$MAS_PREFIX --with-apr-util=$MAS_PREFIX --with-apxs=${MAS_PREFIX}/bin/apxs --with-neon=${MAS_PREFIX} --without-berkeley-db
if [ $? -gt 0 ]; then die "! configuring of subversion failed" 81; fi

echo "-------------------------------------------------------------------------------"
echo "compiling subversion"
echo "-------------------------------------------------------------------------------"
make $QUIET
if [ $? -gt 0 ]; then die "! building of subversion failed" 82; fi

echo "-------------------------------------------------------------------------------"
echo "installing subversion"
echo "-------------------------------------------------------------------------------"
make $QUIET install
if [ $? -gt 0 ]; then die "! installing of subversion failed" 83; fi
echo "@ subversion was built"

echo ""
echo ""
echo "############################################################"
echo "# ADDING SVN ACCESS CONFIGURATION TO HTTPD.CONF"

cat ${WORKING_DIR}/httpd.conf.additions.txt >> ${MAS_PREFIX}/conf/httpd.conf #&& die "### Couldn't add httpd.conf additions ###"
php ${WORKING_DIR}/fix_up_httpd_conf.php ${WORKING_DIR} ${MAS_PREFIX}

echo ""
echo ""
echo "############################################################"
echo "# FINISHED"
echo "############################################################"

# === end of line ===========================================================================================================
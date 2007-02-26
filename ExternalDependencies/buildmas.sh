#!/bin/bash

die()
{
	echo "${1}"
	exit 1
}

# Get full path of folder containing this script:
WORKING_DIR="`dirname $0`"	# This may give a relative path.
cd "$WORKING_DIR"
WORKING_DIR="`pwd`"		# pwd always gives absolute paths.

# get the location of the application bundle outputted by the XCode build
MAS_PREFIX="$WORKING_DIR/../Application/build/Release/MAS.app/Contents/Resources/MAS"
SOURCES_DIR="`echo $WORKING_DIR`/Sources/"

# has the user built the XCode project first?
if ! [ -d "$WORKING_DIR/../Application/build/Release/MAS.app" ]
then
	echo "! the XCode project must be built first"
	echo "  please open 'macsvnserver/Application/MAS.xcodeproj' and click the Build button"
	exit 1
fi

# Have a sources folder? Use it, otherwise extract stuff from
# the Archives folder into a new Sources folder:
if [ -d "$SOURCES_DIR" ]
then
    echo "Using existing Sources folder."
    cd $SOURCES_DIR
else
	echo "############################################################"
	echo "# UNPACKING SOURCES"
	echo ""
	
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
		echo "! some source code archives are missing. please download ExternalDependencies.zip from the MAS website and extract it into the Archives folder"
		exit 1
	fi
	
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
	
	echo ""
	echo "############################################################"
	echo "# RENAMING SOURCE FOLDERS TO EXCLUDE VERSION NUMBER"
	echo ""
	
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
	
	echo ""
	echo "############################################################"
	echo "# CREATING SYMLINKS TO PACKAGES SVN INCLUDES"
	
	ln -sv ../apr subversion/apr
	ln -sv ../apr-util subversion/apr-util
	ln -sv ../neon subversion/neon
fi

# the following needs to be before any builds so it doesn't
# clean away the apr, apr-util and neon builds we just did.
echo ""
echo ""
echo "############################################################"
echo "# CLEANING UP SUBVERSION STUFF"

cd subversion
make -s clean
make -s distclean

echo ""
echo ""
echo "############################################################"
echo "# BUILDING LIBXML2"

#CFLAGS="-O -g -arch i386 -arch ppc -isysroot /Developer/SDKs/MacOSX10.4u.sdk"
CFLAGS="-O -g  -isysroot /Developer/SDKs/MacOSX10.4u.sdk -arch ppc -arch i386"
export CFLAGS
#LDFLAGS="-Wl,-syslibroot,/Developer/SDKs/MacOSX10.4u.sdk"
#export LDFLAGS

cd ../libxml2
./configure -q --prefix=$MAS_PREFIX  --disable-dependency-tracking #&& die "### Couldn't configure libxml2 ###"
if [ $? -gt 0 ]; then echo "! configuring of libxml2 failed"; exit 1; fi
echo "------------------------------------------------------------"
make -s clean
make -s
if [ $? -gt 0 ]; then echo "! building of libxml2 failed"; exit 1; fi
echo "------------------------------------------------------------"
make -s install
if [ $? -gt 0 ]; then echo "! installing of libxml2 failed"; exit 1; fi
echo "------------------------------------------------------------"

echo ""
echo ""
echo "############################################################"
echo "# BUILDING GETTEXT"

cd ../gettext
./configure -q --prefix=$MAS_PREFIX --enable-csharp=no
if [ $? -gt 0 ]; then echo "! configuring of gettext failed"; exit 1; fi
echo "------------------------------------------------------------"
make -s
if [ $? -gt 0 ]; then echo "! building of gettext failed"; exit 1; fi
echo "------------------------------------------------------------"
make -s install
if [ $? -gt 0 ]; then echo "! installing of gettext failed"; exit 1; fi
echo "------------------------------------------------------------"


echo ""
echo ""
echo "############################################################"
echo "# BUILDING NEON"

cd ../neon
./configure -q --prefix=$MAS_PREFIX --with-libs=${MAS_PREFIX}:/usr --with-apxs=${MAS_PREFIX}/bin/apxs
if [ $? -gt 0 ]; then echo "! configuring of neon failed"; exit 1; fi
make -s
if [ $? -gt 0 ]; then echo "! building of neon failed"; exit 1; fi
make -s install
if [ $? -gt 0 ]; then echo "! installing of neon failed"; exit 1; fi


echo ""
echo ""
echo "############################################################"
echo "# BUILDING APR"

cd ../apr
./configure -q --prefix=$MAS_PREFIX --with-libs=${MAS_PREFIX}:/usr
if [ $? -gt 0 ]; then echo "! configuring of apr failed"; exit 1; fi
make -s
if [ $? -gt 0 ]; then echo "! building of apr failed"; exit 1; fi
make -s install
if [ $? -gt 0 ]; then echo "! installing of apr failed"; exit 1; fi


echo ""
echo ""
echo "############################################################"
echo "# BUILDING APR-UTIL"

cd ../apr-util
./configure -q --prefix=$MAS_PREFIX --with-libs=${MAS_PREFIX}:/usr  --with-apr=$MAS_PREFIX --with-iconv=/usr
if [ $? -gt 0 ]; then echo "! configuring of apr-util failed"; exit 1; fi
make -s
if [ $? -gt 0 ]; then echo "! building of apr-util failed"; exit 1; fi
make -s install
if [ $? -gt 0 ]; then echo "! installing of apr-util failed"; exit 1; fi


echo ""
echo ""
echo "############################################################"
echo "# BUILDING HTTPD (Apache 2)"

cd ../httpd
make -s clean
make -s distclean
./configure -q --prefix=$MAS_PREFIX --with-libs=${MAS_PREFIX}:/usr --enable-so --enable-dav-fs --enable-dav-lock --enable-dav --enable-static-htpasswd --enable-static-support --disable-authn-dbd --without-sqlite --with-port=8800
if [ $? -gt 0 ]; then echo "! configuring of httpd failed"; exit 1; fi
make -s
if [ $? -gt 0 ]; then echo "! building of httpd failed"; exit 1; fi
make -s install
if [ $? -gt 0 ]; then echo "! installing of httpd failed"; exit 1; fi


echo ""
echo ""
echo "############################################################"
echo "# BUILDING SUBVERSION"

cd ../subversion
./configure -q --prefix=$MAS_PREFIX --with-libs=${MAS_PREFIX}:/usr --with-apr=$MAS_PREFIX --with-apr-util=$MAS_PREFIX --with-apxs=${MAS_PREFIX}/bin/apxs --with-neon=${MAS_PREFIX}
if [ $? -gt 0 ]; then echo "! configuring of subversion failed"; exit 1; fi
make -s
if [ $? -gt 0 ]; then echo "! building of subversion failed"; exit 1; fi
make -s install
if [ $? -gt 0 ]; then echo "! installing of subversion failed"; exit 1; fi


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

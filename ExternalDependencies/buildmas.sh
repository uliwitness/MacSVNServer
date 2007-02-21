#!/bin/bash

die()
{
	echo "${1}"
	exit 1
}

MAS_PREFIX="/Applications/MAS.app/Contents/Resources/MAS"

# Get full path of folder containing this script:
WORKING_DIR="`dirname $0`"	# This may give a relative path.
cd "$WORKING_DIR"
WORKING_DIR="`pwd`"		# pwd always gives absolute paths.
SOURCES_DIR="`echo $WORKING_DIR`/Sources/"

# Have a sources folder? Use it, otherwise extract stuff from
# the Archives folder into a new Sources folder:
if [ -d "$SOURCES_DIR" ]
then
    echo "Using existing Sources folder."
    cd $SOURCES_DIR
else
mkdir Sources
cd $SOURCES_DIR

echo "############################################################"
echo "# UNPACKING SOURCES"

HTTPD_ARCHIVE="`find ../Archives/ -name 'httpd-*.tar.gz' -print -maxdepth 1`"
LIBXML_ARCHIVE="`find ../Archives/ -name 'libxml2-*.tar.gz' -print -maxdepth 1`"
EXPAT_ARCHIVE="`find ../Archives/ -name 'expat-*.tar.gz' -print -maxdepth 1`"
SVN_ARCHIVE="`find ../Archives/ -name 'subversion-*.tar.gz' -print -maxdepth 1`"
GETTEXT_ARCHIVE="`find ../Archives/ -name 'gettext-*.tar.gz' -print -maxdepth 1`"

echo "$HTTPD_ARCHIVE"
tar -xzf "$HTTPD_ARCHIVE"
echo "$LIBXML_ARCHIVE"
tar -xzf "$LIBXML_ARCHIVE"
echo "$EXPAT_ARCHIVE"
tar -xzf "$EXPAT_ARCHIVE"
echo "$SVN_ARCHIVE"
tar -xzf "$SVN_ARCHIVE"
echo "$GETTEXT_ARCHIVE"
tar -xzf "$GETTEXT_ARCHIVE"


echo "############################################################"
echo "# MOVING FOLDERS TO SOURCES FOLDER UNDER STANDARD NAME"

HTTPD_FOLDER="`find . -name 'httpd-*[^z]' -print -maxdepth 1`"
LIBXML_FOLDER="`find . -name 'libxml2-*[^z]' -print -maxdepth 1`"
EXPAT_FOLDER="`find . -name 'expat-*[^z]' -print -maxdepth 1`"
SVN_FOLDER="`find . -name 'subversion-*[^z]' -print -maxdepth 1`"
GETTEXT_FOLDER="`find . -name 'gettext-*[^z]' -print -maxdepth 1`"

echo "$HTTPD_FOLDER"
mv "$HTTPD_FOLDER" ./httpd
echo "$LIBXML_FOLDER"
mv "$LIBXML_FOLDER" ./libxml2
echo "$EXPAT_FOLDER"
mv "$EXPAT_FOLDER" ./expat
echo "$SVN_FOLDER"
mv "$SVN_FOLDER" ./subversion
echo "$GETTEXT_FOLDER"
mv "$GETTEXT_FOLDER" ./gettext


echo "############################################################"
echo "# CREATING SYMLINKS TO PACKAGES SVN INCLUDES"

ln -s subversion/apr apr
ln -s subversion/apr-util apr-util
ln -s subversion/neon neon
fi

# the following needs to be before any builds so it doesn't
# clean away the apr, apr-util and neon builds we just did.
echo ""
echo ""
echo "############################################################"
echo "# CLEANING UP SUBVERSION STUFF"

cd subversion
make clean
make distclean

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
./configure --prefix=$MAS_PREFIX  --disable-dependency-tracking #&& die "### Couldn't configure libxml2 ###"
echo "------------------------------------------------------------"
make clean
make #&& die "### Couldn't make libxml2 ###"
echo "------------------------------------------------------------"
make install #&& die "### Couldn't install libxml2 ###"
echo "------------------------------------------------------------"


echo ""
echo ""
echo "############################################################"
echo "# BUILDING GETTEXT"

cd ../gettext
./configure --prefix=$MAS_PREFIX --enable-csharp=no #&& die "### Couldn't configure gettext ###"
echo "------------------------------------------------------------"
make #&& die "### Couldn't make gettext ###"
echo "------------------------------------------------------------"
make install #&& die "### Couldn't install gettext ###"
echo "------------------------------------------------------------"


echo ""
echo ""
echo "############################################################"
echo "# BUILDING NEON"

cd ../neon
./configure --prefix=$MAS_PREFIX --with-libs=/Applications/MAS:/usr --with-apxs=${MAS_PREFIX}/bin/apxs #&& die "### Couldn't configure neon ###"
make #&& die "### Couldn't make neon ###"
make install #&& die "### Couldn't install neon ###"


echo ""
echo ""
echo "############################################################"
echo "# BUILDING APR"

cd ../apr
./configure --prefix=$MAS_PREFIX --with-libs=${MAS_PREFIX}:/usr #&& die "### Couldn't configure apr ###"
make #&& die "### Couldn't make apr ###"
make install #&& die "### Couldn't install apr ###"


echo ""
echo ""
echo "############################################################"
echo "# BUILDING APR-UTIL"

cd ../apr-util
./configure --prefix=$MAS_PREFIX --with-libs=${MAS_PREFIX}:/usr  --with-apr=$MAS_PREFIX --with-iconv=/usr #&& die "### Couldn't configure apr-util ###"
make #&& die "### Couldn't make apr-util ###"
make install #&& die "### Couldn't install apr-util ###"


echo ""
echo ""
echo "############################################################"
echo "# BUILDING HTTPD (Apache 2)"

cd ../httpd
make clean
make distclean
./configure --prefix=$MAS_PREFIX --with-libs=${MAS_PREFIX}:/usr --enable-so --enable-dav-fs --enable-dav-lock --enable-dav --enable-static-htpasswd --enable-static-support --disable-authn-dbd --without-sqlite --with-port=8800 #&& die "### Couldn't configure httpd ###"
make #&& die "### Couldn't make httpd ###"
make install #&& die "### Couldn't install httpd ###"


echo ""
echo ""
echo "############################################################"
echo "# BUILDING SUBVERSION"

cd ../subversion
./configure --prefix=$MAS_PREFIX --with-libs=${MAS_PREFIX}:/usr --with-apr=$MAS_PREFIX --with-apr-util=$MAS_PREFIX --with-apxs=${MAS_PREFIX}/bin/apxs --with-neon=${MAS_PREFIX} #&& die "### Couldn't configure subversion ###"
make #&& die "### Couldn't make subversion ###"
make install #&& die "### Couldn't install subversion ###"


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

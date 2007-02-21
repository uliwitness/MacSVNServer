MAS - MacOS X / Apache / Subversion
-----------------------------------

Apache (http://apache.org/) and Subversion (http://subversion.tigris.org) are open source software. Get the source code to compile your own customised versions from the official project web sites. Most of the work of MAS is done by them. I'm simply standing on the shoulders of giants.


WHAT IS IT?
MAS is a self-contained package for easily running a subversion repository on your Mac.

* This is a pre-release version for testing. Do not pass this on, and don't use it on valuable data! *


HOW DO I USE IT?
To use it, make sure you have dropped the "MAS" application into your Applications folder (/Applications, so it is at /Applications/MAS.app). It will not work elsewhere. Then start it up.

You have to create a new user before you can use MAS (File -> New User), but if you forget that, it should ask. On first startup, MAS will create a "svn-auth-file" file in /Library/Application Support/MAS/ and a new repository in /Library/Application Support/MAS/repositories/. If you want to completely uninstall MAS, you will have to delete these two as well. However, be aware that these folders are where your data goes, so that will be gone as well.


MANAGING USERS
To create a user, use the File -> New User menu item. Double-click one of the users in the "Users & Groups" window to change its password.


TROUBLESHOOTING
MAS requires special permissions. The only way you can maintain them is by transferring MAS as a ZIP archive and unpacking MAS on the volume you want to use it on. Once it's on the right volume, you can move it to the correct folder using the Finder.


WHO DID THIS?
M. Uli Kusterer (kusterer (at) gmail (dot) com). Get the newest version of MAS and other info from <http://www.zathras.de>.


(c) 2006, all rights reserved.
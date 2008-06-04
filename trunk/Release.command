#!/bin/sh
cd "`dirname \"$0\"`"

echo "Peacock Release Script"

# Update to latest build
echo
echo "Updating working directory"
svn update
echo
read -p "Press enter key to continue when done..."

# Check status
echo
echo "Checking status working directory"
svn status
echo
read -p "Press enter key to continue when done..."

# Get some info
echo
VERSION=`defaults read /Users/jkool/Developer/Peacock/trunk/Info CFBundleShortVersionString`
echo "Release version = $VERSION"
SUBVERSIONVERSION=`svn info -r HEAD | grep "Revision" | sed 's/Revision: //'`
echo "Current SVN version = $SUBVERSIONVERSION"
SUFEEDURL=`defaults read /Users/jkool/Developer/Peacock/trunk/Info SUFeedURL`
PREVIOUSSUBVERSIONVERSION=`curl -s $SUFEEDURL | grep -o "sparkle:version=\W\w*\W" | tail -1 | sed 's/sparkle:version="//' | sed 's/"//'`
echo "Previous SVN version = $PREVIOUSSUBVERSIONVERSION"
echo
read -p "Press enter key to continue..."
#read -p 'Previous SVN version (e.g. 88) : ' PREVIOUSSUBVERSIONVERSION

# Create release notes for Credits.rtf
echo
echo "Release notes:"
NEXTSUBVERSIONVERSION=$((SUBVERSIONVERSION+1))
echo "	Version $VERSION ($NEXTSUBVERSIONVERSION) ("`date "+%a, %e %b %Y %H:%M"`")"
echo
echo "	Changes in this build:"
svn log -r $PREVIOUSSUBVERSIONVERSION:$SUBVERSIONVERSION --incremental > temp_release_notes
tee < temp_release_notes | grep -e "\[" | sed 's/^/	- /'
echo
open -e English.lproj/Credits.rtf
echo "Copy the text above to Credits.rtf and save your changes"
echo
read -p "Press enter key to continue when done..."

# Commit changes for Credits.rtf
echo
svn commit -m "Build for version $VERSION"
SUBVERSIONVERSION=`svn info -r HEAD | grep "Revision" | sed 's/Revision: //'`
echo "Commited Credits.rtf changes to SVN"
echo "Current SVN version = $SUBVERSIONVERSION"
echo
read -p "Press enter key to continue..."

# # Check status
# echo
# echo "Checking status working directory"
# svn status
# echo
# read -p "Press enter key to continue when done..."

# Build Release
echo
echo "Build Release version of Peacock"
xcodebuild -configuration Release | grep "warning"|"error"
echo
read -p "Press enter key to continue..."

# # Create DMG file
# echo
# echo "Launching DMG Packager"
# open -a ~/Applications/DMG\ Packager.app
# echo
# echo "Next click 'Package DMG'"
# echo
# read -p "Press enter key to continue when done..."

# Create DMG file (alternative method)
echo
echo "Creating DMG file"
dmgcanvas -t Peacock.dmgCanvas -o ~/Developer/Releases/Peacock-releases/Peacock_$VERSION.dmg
echo
read -p "Press enter key to continue..."

# Rename file and get some info
echo
echo "Determining DSA signature for file"
DSA=`openssl dgst -sha1 -binary < ~/Developer/Releases/Peacock-releases/Peacock_$VERSION.dmg | openssl dgst -dss1 -sign dsa_priv.pem | openssl enc -base64`
#MD5=`md5 ~/Developer/Releases/Peacock-releases/Peacock_$VERSION.dmg | sed 's/^.*= //'`
LENGTH=`ls -l ~/Developer/Releases/Peacock-releases/Peacock_$VERSION.dmg | sed 's/.* jkool *//' | sed 's/ .*//'`

# Upload to website
echo
echo "Launching Transmit"
open -a /Applications/Transmit.app
echo
echo "Upload file to website."
open ~/Developer/Releases/Peacock-releases/
echo
read -p "Press enter key to continue when done..."

# Create XML entry
echo
echo "Release notes for XML"
echo "<item>"
echo "	<title>Version "$VERSION"</title>"
echo "	<description><![CDATA["
echo "	<p>Changes in this build:</p><ul>" 
tee < temp_release_notes | grep -e "\[" | sed 's/^/	<li>/' | sed 's/$/<\/li>/'
echo "	</ul>"
echo 
echo "	<p><b>Stay up-to-date:</b></br />"
echo "	Feedback is always welcome. You can now also subscribe to a mailing list to stay up-to-date on the latest news regarding Peacock. More information on the website: <a href=\"http://peacock.johankool.nl\">http://peacock.johankool.nl/</a>."
echo "	</p>	]]></description>"
echo "	<pubDate>"`date "+%a, %e %b %Y %H:%M:%S %Z"`"</pubDate>"
echo "	<enclosure sparkle:shortVersionString=\""$VERSION"\" sparkle:version=\""$SUBVERSIONVERSION"\" sparkle:dsaSignature=\""$DSA"\" url=\"http://peacock.johankool.nl/releases/Peacock_"$VERSION".dmg\" length=\""$LENGTH"\" type=\"application/octet-stream\"/>"
echo "</item>"
echo
echo "Copy the above to peacock.xml"
echo
read -p "Press enter key to continue when done..."

# Write Announcement mail
echo
echo "Sent Announcement Mail"
echo
echo "Release notes for E-mail:"
echo "Changes in this build:"
tee < temp_release_notes | grep -e "\[" | sed 's/^/- /'
echo
read -p "Press enter key to continue when done..."

# Put Note on website
echo
echo "Put Note on Website"
echo
echo "Title blogpost: Peacock $VERSION"
echo "Blogpost content:"
echo "<p>Today a new version of <a href=\"http://peacock.johankool.nl/\">Peacock</a> is released. </p>"
echo "<!--more-->"
echo "<p>Changes in this build:</p>"
echo "<ul>"
tee < temp_release_notes | grep -e "\[" | sed 's/^/<li>/' | sed 's/$/<\/li>/'
echo "</ul>"
echo "<p>Feedback is always welcome.</p>"
echo
read -p "Press enter key to continue when done..."

# Update version number in registration form on website
# echo
# echo "Update version number in registration form on website"
# echo
# echo "version in http://peacock.johankool.nl/registration/Config.php needs updating"

# Cleanup
echo
echo "Cleaning up temporary file(s)"
rm temp_release_notes

# Done
echo
echo "Done"
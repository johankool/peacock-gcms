#!/bin/sh
cd "`dirname \"$0\"`"

echo "Peacock Release Note Generator"

# Check status
echo
echo "Checking status working directory"
svn status
echo
read -p "Press enter key to continue when done..."

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
SUBVERSIONVERSION=`svn info -r HEAD | grep "Revision" | sed 's/Revision: //'`
read -p 'Release version (e.g. 0.23)    : ' VERSION
echo "Current SVN version = $SUBVERSIONVERSION"
read -p 'Previous SVN version (e.g. 88) : ' PREVIOUSSUBVERSIONVERSION

# Create release notes for Credits.rtf
echo
echo "Release notes:"
NEXTSUBVERSIONVERSION=$((SUBVERSIONVERSION+1))
echo "	Version $VERSION ($NEXTSUBVERSIONVERSION) ("`date "+%a, %e %b %Y %H:%M"`")"
echo
echo "	Changes in this build:"
svn log -r $PREVIOUSSUBVERSIONVERSION:$SUBVERSIONVERSION --incremental | grep -e "\[" | sed 's/^/	- /'
echo
open -e English.lproj/Credits.rtf
echo "Copy the text above to Credits.rtf"
echo
read -p "Press enter key to continue when done..."

# Commit changes for Credits.rtf
echo
svn commit -m "Build for version $VERSION"
SUBVERSIONVERSION=`svn info -r HEAD | grep "Revision" | sed 's/Revision: //'`
echo "Commited Credits.rtf changes to SVN"
echo "Current SVN version = $SUBVERSIONVERSION"

# Check status
echo
echo "Checking status working directory"
svn status
echo
read -p "Press enter key to continue when done..."

# Build Release
echo
echo "Build Release version of Peacock"
xcodebuild -configuration Release | grep "warning"|"error"

# Create DMG file
echo
echo "Launching DMG Packager"
open -a ~/Applications/DMG\ Packager.app
echo
echo "Next click 'Package DMG'"
echo
read -p "Press enter key to continue when done..."

# Rename file and get some info
mv /Users/jkool/Developer/Releases/Peacock\ releases/Peacock_release.dmg /Users/jkool/Developer/Releases/Peacock\ releases/Peacock_$VERSION.dmg
MD5=`md5 /Users/jkool/Developer/Releases/Peacock\ releases/Peacock_$VERSION.dmg | sed 's/^.*= //'`
LENGTH=`ls -l /Users/jkool/Developer/Releases/Peacock\ releases/Peacock_$VERSION.dmg | sed 's/.* jkool *//' | sed 's/ .*//'`

# Upload to website
echo
echo "Launching Transmit"
open -a /Applications/Transmit.app
echo
echo "Upload file to website."
open /Users/jkool/Developer/Releases/Peacock\ releases/
echo
read -p "Press enter key to continue when done..."

# Create XML entry
echo
echo "Release notes for XML"
echo "<item>"
echo "	<title>Version "$VERSION"</title>"
echo "	<description><![CDATA["
echo "	<p>Changes in this build:</p><ul>" 
svn log -r $PREVIOUSSUBVERSIONVERSION:$SUBVERSIONVERSION --incremental | grep -e "\[" | sed 's/^/	<li>/' | sed 's/$/<\/li>/'
echo "	</ul>"
echo 
echo "	<p><b>Stay up-to-date:</b></br />"
echo "	Feedback is always welcome. You can now also subscribe to a mailing list to stay up-to-date on the latest news regarding Peacock. More information on the website: <a href=\"http://peacock.johankool.nl\">http://peacock.johankool.nl/</a>."
echo "	</p>	]]></description>"
echo "	<pubDate>"`date "+%a, %e %b %Y %H:%M:%S %Z"`"</pubDate>"
echo "	<enclosure sparkle:shortVersionString=\""$VERSION"\" sparkle:version=\""$SUBVERSIONVERSION"\" sparkle:md5Sum=\""$MD5"\" url=\"http://peacock.johankool.nl/releases/Peacock_"$VERSION".dmg\" length=\""$LENGTH"\" type=\"application/octet-stream\"/>"
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
svn log -r $PREVIOUSSUBVERSIONVERSION:$SUBVERSIONVERSION --incremental | grep -e "\[" | sed 's/^/- /'
echo
read -p "Press enter key to continue when done..."

# Put Note on website
echo
echo "Put Note on Website"
echo
echo "Release notes for HTML:"
echo "<ul>"
svn log -r $PREVIOUSSUBVERSIONVERSION:$SUBVERSIONVERSION --incremental | grep -e "\[" | sed 's/^/<li>/' | sed 's/$/<\/li>/'
echo "</ul>"
echo
read -p "Press enter key to continue when done..."

# Done
echo
echo "Done"
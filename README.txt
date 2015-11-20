GreekNameDays

Orthodox Namedays retrieval and presentation tool


Description

GreekNameDays is a bash script that fetches the names of those who celebrate
today and tomorrow from the site www.eortologio.gr and presents them on the
desktop using the graphical tool YAD.


Installation

All

sudo -H sh -c '
	cp -fv Christian-cross.png /usr/share/pixmaps/
	cp -fv greeknamedays.sh /usr/local/bin/greeknamedays
	desktop-file-install greeknamedays.desktop
'

Uninstallation

All

sudo -H sh -c '
	rm -fv /usr/share/applicationsgreeknamedays.desktop
	rm -fv /usr/share/pixmaps/Christian-cross.png
	rm -fv /usr/local/bin/greeknamedays
'


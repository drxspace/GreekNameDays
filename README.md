# GreekNameDays
Orthodox Namedays retrieval and presentation tool.

## Description
GreekNameDays is a bash script that fetches the names of those who celebrate
today, tomorrow and the day after tomorrow from the site [www.eortologio.gr] and
presents them on the desktop using the graphical tool [YAD].

## Prerequisites
As recent as possible version of graphical tool [YAD].

## Installation
Download and extract the zip file, open in terminal (navigate to) this directory
and issue the command below.

### All

```bash
sudo -H sh -c '
	cp -fv greeknamedays.png /usr/share/pixmaps/
	cp -fv greeknamedays.sh /usr/local/bin/greeknamedays
	desktop-file-install greeknamedays.desktop
'
```

## Uninstallation
Open terminal and issue the command below.

### All

```bash
sudo -H sh -c '
	rm -fv /usr/share/applications/greeknamedays.desktop
	rm -fv /usr/share/pixmaps/greeknamedays.png
	rm -fv /usr/local/bin/greeknamedays
'
```

[www.eortologio.gr]: <http://www.eortologio.gr>
[YAD]: <http://sourceforge.net/projects/yad-dialog/>

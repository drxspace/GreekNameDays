#!/usr/bin/env bash
#
# _________        ____  ____________         _______ ___________________
# ______  /__________  |/ /___  ____/________ ___    |__  ____/___  ____/
# _  __  / __  ___/__    / ______ \  ___  __ \__  /| |_  /     __  __/
# / /_/ /  _  /    _    |   ____/ /  __  /_/ /_  ___ |/ /___   _  /___
# \__,_/   /_/     /_/|_|  /_____/   _  .___/ /_/  |_|\____/   /_____/
#                                    /_/           drxspace@gmail.com
#
#set -e
#set -x

version='0.4.2'

# Make sure your DISPLAY and XAUTHORITY variables are set in the environment the script is running in
Encoding=UTF-8
LANG=en_US.UTF-8
[[ -z "$DISPLAY" ]] && {
	display=`/bin/ps -Afl | /bin/grep Xorg | /bin/grep -v grep | /usr/bin/awk '{print $16 ".0"}'`
	export DISPLAY=$display
}
[[ -z "$XAUTHORITY" ]] && [[ -e "$HOME/.Xauthority" ]] && export XAUTHORITY="$HOME/.Xauthority";

# The directory this script resides
#scriptDir="$(dirname "$0")"

# Store temporary data in this directory
cacheDir="$HOME/.cache/NameDays"

# Cleaner trap
trap 'rm -rf ${cacheDir}' EXIT

# Server uri
eortologioRSS="http://www.eortologio.gr/rss/si_av_me_el.xml"

# Prerequisites
#[[ -x $(which yad) ]] || {
if ! hash yad &>/dev/null; then
	notify-send "Greek NameDays" "yad command is missing\nUse sudo apt-get install yad to install it" -i face-embarrassed;
	exit 1;
fi

# wrapText () function that wraps the given string if it's >N chars
wrapText () {
	local wrapChar=$(( 40 * 2 ))
	echo "${1}" | fold -s -w ${2-${wrapChar}}
	# | sed -e 's/[[:blank:]]*//g' | sed -e 's/[[:blank:]]*$/\\n/' | sed -e 's/^[[:blank:]]*//'
	return
}

# ColourizeNames function
ColourizeNames () {
	if [[ $(grep "δεν υπάρχει μια" <<< "${1}" 2> /dev/null) ]]; then
		echo -n "<span color='#E39700'>Δεν υπάρχει κάποια ευρέως γνωστή γιορτή</span>";
	else
		echo -n "<span color='#0A0A0A' font_size='large'>${1}</span>";
	fi
	return
}

####
#
# main
#

mkdir -p "${cacheDir}"
cat /dev/null > "${cacheDir}/names"

yad --form \
    --width="420" \
    --borders="10" \
    --window-icon="/usr/share/pixmaps/greeknamedays.png" \
    --image="dialog-information" \
    --image-on-top \
    --center \
    --no-buttons \
    --timeout="20" \
    --timeout-indicator="bottom" \
    --title=$"Ελληνικές Ονομαστικές Εορτές, έκδ. ${version}" \
    --text=$"Γίνεται ανάκτηση τυχόν ονομάτων από τον ιστότοπο <a href='http://www.eortologio.gr/'>www.eortologio.gr</a>
Παρακαλώ περιμένετε..." &
INFOpid=$(echo $!)

secs=20					# Set interval (duration) in seconds.
endTime=$(( $(date +%s) + secs ))	# Calculate end time.
while [[ ! -s "${cacheDir}/names" ]] && [[ $(date +%s) -le $endTime ]]; do
	wget -q -N -4 -O "${cacheDir}/names" ${eortologioRSS};
done

eval "kill -15 ${INFOpid}" &> /dev/null

[[ ! -s "${cacheDir}/names" ]] && {
	echo "Error while retrieving names from server." 1>&2
	yad --form \
	    --width="420" \
	    --borders="10" \
	    --window-icon="/usr/share/pixmaps/greeknamedays.png" \
	    --image="dialog-error" \
	    --image-on-top \
	    --center \
	    --buttons-layout="center" \
	    --button=$"Κλείσιμο!window-close!Κλείνει το παράθυρο:1" \
	    --title=$"Ελληνικές Ονομαστικές Εορτές, έκδ. ${version}" \
	    --text=$"Η ανάκτηση τυχόν ονομάτων από τον ιστότοπο <a href='http://www.eortologio.gr/'>www.eortologio.gr</a> δεν κατέστη δυνατή.
Παρακαλώ ελέγξτε τη σύνδεσή σας στο διαδίκτυο και/ή δοκιμάστε αργότερα..."
	exit 2;
}

iconv -f ISO-8859-7 -t UTF-8 "${cacheDir}/names" | \
	sed 's/>[[:blank:]]*</>\n</g' | \
	sed '/<item>/,/<\/item>/!d' | \
	sed -n 's/.*<title>\(.*\)<\/title>.*/\1/p' > "${cacheDir}"/namedays.xml

WDITD="$(sed -n '/^σήμερα/s/σήμερα[[:blank:]]\(.[^:]*\)[[:blank:]].*/\1/p' "${cacheDir}"/namedays.xml)"
WDITM="$(sed -n '/^αύριο/s/αύριο[[:blank:]]\(.[^:]*\)[[:blank:]].*/\1/p' "${cacheDir}"/namedays.xml)"
WDIDATM="$(sed -n '/^μεθαύριο/s/μεθαύριο[[:blank:]]\(.[^:]*\)[[:blank:]].*/\1/p' "${cacheDir}"/namedays.xml)"

TodayNames="$(ColourizeNames "$(wrapText "$(sed -n '/^σήμερα/s/^.[^:]*:.\(.*\)..πηγή.*/\1/p' "${cacheDir}"/namedays.xml)")")"
TomorrowNames="$(ColourizeNames "$(wrapText "$(sed -n '/^αύριο/s/^.[^:]*:.\(.*\)..πηγή.*/\1/p' "${cacheDir}"/namedays.xml)")")"
DayAfterTomorrowNames="$(ColourizeNames "$(wrapText "$(sed -n '/^μεθαύριο/s/^.[^:]*:.\(.*\)..πηγή.*/\1/p' "${cacheDir}"/namedays.xml)")")"

yad --form \
    --width="420" \
    --borders="10" \
    --center \
    --timeout="60" \
    --timeout-indicator="left" \
    --title=$"Ελληνικές Ονομαστικές Εορτές, έκδ. ${version}" \
    --window-icon="/usr/share/pixmaps/greeknamedays.png" \
    --image-on-top \
    --image="/usr/share/pixmaps/greeknamedays.png" \
    --buttons-layout="center" \
    --button=$"Κλείσιμο!window-close!Κλείνει το παράθυρο:0" \
    --text=$"<span color='blue' font_size='medium' font_weight='bold'>Σήμερα, ${WDITD}</span>\n${TodayNames}\n\n<span color='blue' font_size='medium' font_weight='bold'>Αύριο, ${WDITM}</span>\n${TomorrowNames}\n\n<span color='blue' font_size='medium' font_weight='bold'>Μεθαύριο, ${WDIDATM}</span>\n${DayAfterTomorrowNames}\n\
$([[ "${WDITD}" =~ "$(date +"%a")" ]] || echo -en "\n<span color='red' underline='error'>Πιθανό πρόβλημα. Ασύμπτωτες ημερομηνίες!</span>\n")"

exit 0

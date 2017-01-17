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

version='0.2.6'

Encoding=UTF-8

# The directory this script resides
#scriptDir="$(dirname "$0")"

# Store temporary data in this directory
cacheDir="$HOME/.cache/NameDays"

# Getting access to the display
LANG=en_US.UTF-8
[[ -z "$DISPLAY" ]] && export DISPLAY=:0;
[[ -z "$XAUTHORITY" ]] && [[ -e "$HOME/.Xauthority" ]] && export XAUTHORITY="$HOME/.Xauthority";

# Prerequisites
#[[ -x $(which yad) ]] || {
if ! hash yad &>/dev/null; then
	notify-send "Greek NameDays" "yad command is missing\nUse sudo apt-get install yad to install it" -i face-embarrassed;
	exit 1;
fi

# CleanUp function
CleanUp () {
	rm -rf "${cacheDir}"
}

# ColorWrapNames function
ColorWrapNames () {
	if [[ $(grep "δεν υπάρχει μια" <<< "${1}" 2> /dev/null) ]]; then
		echo -n "<span color='#E39700'>Δεν υπάρχει κάποια ευρέως γνωστή γιορτή</span>";
	else
		echo -n "<span color='#0A0A0A' font_size='large'>${1}</span>";
	fi
}

eortologioRSS="http://www.eortologio.gr/rss/si_av_me_el.xml"

####
#
# main
#

mkdir -p "${cacheDir}"

yad --image=info \
    --width=520 \
    --height=80 \
    --borders=10 \
    --image-on-top \
    --center \
    --no-buttons \
    --timeout=20 \
    --timeout-indicator=bottom \
    --title=$"Ελληνικές Ονομαστικές Εορτές, έκδ. ${version}" \
    --text=$"Γίνεται ανάκτηση τυχόν ονομάτων από τον ιστότοπο <a href='http://www.eortologio.gr/'>www.eortologio.gr</a>
Παρακαλώ περιμένετε..." &
INFOpid=$(echo $!)

touch "${cacheDir}/names"

secs=1					# Set interval (duration) in seconds.
endTime=$(( $(date +%s) + secs ))	# Calculate end time.
while [[ ! -s "${cacheDir}/names" ]] && [[ $(date +%s) -lt $endTime ]]; do
	wget -q -N -4 -O "${cacheDir}/names" ${eortologioRSS};
done

eval 'kill -15 ${INFOpid}' &> /dev/null

[[ ! -s "${cacheDir}/names" ]] && {
	echo "Error while retrieving names from server." 1>&2
	yad --image=error \
	    --width=520 \
	    --borders=10 \
	    --image-on-top \
	    --center \
	    --buttons-layout=center \
	    --button=Κλείσιμο \
	    --title=$"Ελληνικές Ονομαστικές Εορτές, έκδ. ${version}" \
	    --text=$"Η ανάκτηση τυχόν ονομάτων από τον ιστότοπο <a href='http://www.eortologio.gr/'>www.eortologio.gr</a> δεν κατέστη δυνατή.\n
Παρακαλώ ελέγξτε τη σύνδεσή σας στο διαδίκτυο και/ή δοκιμάστε αργότερα..."
	CleanUp;
	exit 2;
}

iconv -f ISO-8859-7 -t UTF-8 "${cacheDir}/names" | \
	sed 's/>[[:space:]]*</>\n</g' | \
	sed '/<item>/,/<\/item>/!d' | \
	sed -n 's/.*<title>\(.*\)<\/title>.*/\1/p' > "${cacheDir}"/namedays.xml

WDITD="$(sed -n '/^σήμερα/s/σήμερα[[:space:]]\(.[^:]*\)[[:space:]].*/\1/p' "${cacheDir}"/namedays.xml)"
WDITM="$(sed -n '/^αύριο/s/αύριο[[:space:]]\(.[^:]*\)[[:space:]].*/\1/p' "${cacheDir}"/namedays.xml)"
WDIDATM="$(sed -n '/^μεθαύριο/s/μεθαύριο[[:space:]]\(.[^:]*\)[[:space:]].*/\1/p' "${cacheDir}"/namedays.xml)"

TodayNames=$(ColorWrapNames "$(sed -n '/^σήμερα/s/^.[^:]*: \(.*\) (πηγή.*/\1/p' "${cacheDir}"/namedays.xml)")
TomorrowNames=$(ColorWrapNames "$(sed -n '/^αύριο/s/^.[^:]*: \(.*\) (πηγή.*/\1/p' "${cacheDir}"/namedays.xml)")
DayAfterTomorrowNames=$(ColorWrapNames "$(sed -n '/^μεθαύριο/s/^.[^:]*: \(.*\) (πηγή.*/\1/p' "${cacheDir}"/namedays.xml)")

yad --width=500 \
    --borders=10 \
    --image-on-top \
    --center \
    --timeout=60 \
    --timeout-indicator=left \
    --title=$"Ελληνικές Ονομαστικές Εορτές, έκδ. ${version}" \
    --window-icon=greeknamedays \
    --image=greeknamedays \
    --buttons-layout=center \
    --button=Κλείσιμο \
    --text=$"<span color='blue' font_size='medium' font_weight='bold'>Σήμερα, ${WDITD}</span>\n${TodayNames}\n
<span color='blue' font_size='medium' font_weight='bold'>Αύριο, ${WDITM}</span>\n${TomorrowNames}\n
<span color='blue' font_size='medium' font_weight='bold'>Μεθαύριο, ${WDIDATM}</span>\n${DayAfterTomorrowNames}\
$([[ "${WDITD}" =~ "$(date +"%a")" ]] || echo -en "\n\n<span color='red' underline='error'>Πιθανό πρόβλημα. Ασύμπτωτες ημερομηνίες!</span>")"

CleanUp

exit 0

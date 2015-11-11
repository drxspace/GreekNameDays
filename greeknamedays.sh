#!/bin/bash
#
# _________        ____  ____________         _______ ___________________
# ______  /__________  |/ /___  ____/________ ___    |__  ____/___  ____/
# _  __  / __  ___/__    / ______ \  ___  __ \__  /| |_  /     __  __/
# / /_/ /  _  /    _    |   ____/ /  __  /_/ /_  ___ |/ /___   _  /___
# \__,_/   /_/     /_/|_|  /_____/   _  .___/ /_/  |_|\____/   /_____/
#                                    /_/           drxspace@gmail.com
#
#set -e
Encoding=UTF-8
# The directory this script resides
scriptDir="$(dirname "$0")"
# Store temporary data in this directory
cacheDir="$HOME/.cache/NameDay"

# Getting access to the display
if [[ -z "$DISPLAY" ]]; then
	export DISPLAY=$(/bin/ps -Afl | /bin/grep Xorg | /bin/grep -v grep | /usr/bin/awk '{print $16 ".0"}');
fi
if [[ -z "$XAUTHORITY" ]] && [[ -e "$HOME/.Xauthority" ]]; then
	export XAUTHORITY="$HOME/.Xauthority";
fi

# ColorWrapNames function
ColorWrapNames () {
	if [[ $(grep "δεν υπάρχει μια" <<< "${1}" 2> /dev/null) ]]; then
		echo -n "<span color='#E39700'>Δεν υπάρχει κάποια ευρέως γνωστή γιορτή</span>";
	else
		echo -n "<span color='#246C48' font_size='large'>${1}</span>";
	fi
}

# CleanUp function
CleanUp () {
	rm -rf "${cacheDir}"
}

####
#
# main
#
mkdir -p "${cacheDir}"

yad --image=info \
    --width=520 \
    --height=80 \
    --center \
    --no-buttons \
    --timeout=20 \
    --timeout-indicator=bottom \
    --title=$"Ελληνικές Ονομαστικές Εορτές" \
    --text=$"Γίνεται ανάκτηση τυχόν ονομάτων από τον ιστότοπο <a href='http://www.eortologio.gr/'>www.eortologio.gr</a>
Παρακαλώ περιμένετε..." &
INFOpid=$(echo $!)

touch "${cacheDir}/names"

secs=21					# Set interval (duration) in seconds.
endTime=$(( $(date +%s) + secs ))	# Calculate end time.
while [[ ! -s "${cacheDir}/names" ]] && [[ $(date +%s) -lt $endTime ]]; do
	wget -q -N -4 -O "${cacheDir}/names" http://www.eortologio.gr/rss/si_av_el.xml; #… &
	#wait $! # Wait for all background processes to finish before proceeding
done

eval 'kill -15 ${INFOpid}' &> /dev/null

[[ ! -s "${cacheDir}/names" ]] && {
	echo "Error while retrieving names from server." 1>&2
	yad --image=error \
	    --width=520 \
	    --center \
	    --buttons-layout=center \
	    --button=Κλείσιμο \
	    --title=$"Ελληνικές Ονομαστικές Εορτές" \
	    --text=$"Η ανάκτηση τυχόν ονομάτων από τον ιστότοπο <a href='http://www.eortologio.gr/'>www.eortologio.gr</a> δεν κατέστη δυνατή.

Παρακαλώ ελέγξτε τη σύνδεσή σας στο διαδίκτυο και/ή δοκιμάστε αργότερα..."
	CleanUp;
	exit 1;
}

iconv -f ISO-8859-7 -t UTF-8 "${cacheDir}/names" | \
sed 's/>[:space:]*</>\n</g' | \
sed '/<item>/,/<\/item>/!d' | \
sed -n -e 's/.*<title>\(.*\)<\/title>.*/\1/p' > "${cacheDir}"/namedays.xml

TodayNames=$(ColorWrapNames "$(sed -n '/σήμερα/s/^.*: \(.*\) (πηγή.*/\1/p' "${cacheDir}"/namedays.xml)")

TomorrowNames=$(ColorWrapNames "$(sed -n '/αύριο/s/^.*: \(.*\) (πηγή.*/\1/p' "${cacheDir}"/namedays.xml)")

yad --width=400 \
    --center \
    --timeout=20 \
    --timeout-indicator=left \
    --title=$"Ελληνικές Ονομαστικές Εορτές" \
    --window-icon=Christian-cross
    --licon=Christian-cross \
    --image=Christian-cross \
    --buttons-layout=center \
    --button=Κλείσιμο \
    --text=$"<span color='blue' font_size='medium' font_weight='bold'>Σήμερα:</span>\n${TodayNames}

<span color='blue' font_size='medium' font_weight='bold'>Αύριο:</span>\n${TomorrowNames}"

CleanUp

exit 0

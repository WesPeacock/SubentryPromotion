#!/bin/bash
# The next 3 variables should be set before the script is run
# if they're not, a default is used
#set -x
dbname="${dbname:-BearBullMole-complex.db}"
semarkers="${semarkers:-sec sed sei sep sesec sesed sesep seses}"
inifile="${inifile:-Sample-lc.ini}"
# promodbname is set to dbname with '-promo' inserted into if before the extension
promodbname="${dbname%.*}" # take off extension
if [ "$promodbname" == "${dbname##*.}" ]; then # no extension
	promodbname="$promodbname-promo"
else
	promodbname="$promodbname-promo.${dbname##*.}"
fi
# a couple of temporary filenames
from=$(mktemp)
to=$(mktemp)
cp "$dbname"  $from
for sfm in $semarkers
do
	echo "Promoting $sfm fields"
	./se2lx.pl --section se2lx_$sfm  --inifile $inifile <$from >$to
	cp $to $from
done
cp $to "$promodbname"
rm $from $to
echo "Database \"$promodbname\" now contains these promoted subentries (count & type):"
grep '\\spec' <"$promodbname"|cut -c6-99 |sort|uniq -c

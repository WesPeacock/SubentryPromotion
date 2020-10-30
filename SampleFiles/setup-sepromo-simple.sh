ghubadd="${ghubadd:-https://github.com/sil-dictionary-lexical-services/SubentryPromotion/blob/master}"
wget -O BearBullMole-Initial-Empty.fwbackup  "$ghubadd/SampleFiles/BearBullMole-Initial-Empty.fwbackup?raw=true"
wget -O BearBullMole-simple-promo-import-settings.map "$ghubadd/SampleFiles/BearBullMole-complex-promo-import-settings.map?raw=true"
wget -O- "$ghubadd/SampleFiles/BearBullMole-complex.db?raw=true" | perl -pE 's/^\\(se)+/\\se/' | perl -pE 's/(^\\(se)*). /$1 /' > BearBullMole-simple.db
wget -O- "$ghubadd/se2lx/runse2lx.sh?raw=true" | perl -pE 's/dbname:-[^\}]*/dbname:-BearBullMole-simple.db/;s/semarkers:-[^\}]*/semarkers:-se/;s/inifile:-[^\}]*/inifile:-se2lx.ini/' > runse2lx-simple.sh
wget -O se2lx.ini "$ghubadd/se2lx/se2lx.ini?raw=true"
wget -O se2lx.pl "$ghubadd/se2lx/se2lx.pl?raw=true"
wget -O ModelEntries-MDFroot-import-settings.map  "$ghubadd/Var2Compform/ModelEntries-MDFroot-import-settings.map?raw=true"
wget -O ModelEntries-MDFroot.db  "$ghubadd/Var2Compform/ModelEntries-MDFroot.db?raw=true"
wget -O PromoteSubentries.ini  "$ghubadd/Var2Compform/PromoteSubentries.ini?raw=true"
wget -O runVar2Compform.sh  "$ghubadd/Var2Compform/runVar2Compform.sh?raw=true"
wget -O Var2Compform.pl  "$ghubadd/Var2Compform/Var2Compform.pl?raw=true"
dos2unix *

#!/bin/bash
# by Anoushka Joglekar. Edited March 2020, July 2020
# Required input args:

function checkForFile {
        file=$1;
        if [ ! -f $file ]
        then
                echo "ERROR:"$file" is not a regular file ... exiting "
                exit;
        fi
}

function checkForDirectory {
        dir=$1;
        if [ ! -d $dir ]
        then
                echo "ERROR:"$dir" is not a regular directory ... exiting "
                exit;
        fi
}


BarcodeOutput=$1
GeneGZ=$2
StretchesGZ=$3
minTimesObserve=$4
compStr="CagePolyA.complete."

checkForFile $BarcodeOutput
checkForFile $GeneGZ
checkForFile $StretchesGZ

awk -v gGZ=$GeneGZ -v bcO=$BarcodeOutput 'BEGIN{comm="zcat <"gGZ; while(comm|getline) \
{if($2!="none" && $3=="fineRead" && $4=="fineGene") {gene[$1]=$2;}} \
comm="cat "bcO; while(comm|getline) {split($1,rN,"@"); {if(rN[2]".path1" in gene) \
{print $0"\t"gene[rN[2]".path1"]}}}}' | grep -v "@;@" > LongReadInfo/Mapped_Barcoded


if [[ $stretchesGZ == *$compStr*  ]];
then

awk -v sGZ=$StretchesGZ -v mTO=$minTimesObserve 'BEGIN{comm="zcat <"sGZ; \
while(comm|getline) {split($3,rN,/=|.path1/); {name[rN[2]]=rN[2]; \
num[rN[2]]=$1; nov[rN[2]]=$2; stretch[rN[2]]=$5"&&"$4"&&"$6; !Uiso[$5"&&"$4"&&"$6]++;}} \
for(i in name){if(stretch[i] in Uiso && Uiso[stretch[i]]>=mTO) \
{print name[i],num[i],nov[i],stretch[i]}} }' > LongReadInfo/tmp

else
awk -v sGZ=$StretchesGZ -v mTO=$minTimesObserve 'BEGIN{comm="zcat <"sGZ; \
while(comm|getline) {split($3,rN,/=|.path1/); \
{name[rN[2]]=rN[2];num[rN[2]]=$1;nov[rN[2]]=$2;stretch[rN[2]]=$4;!Uiso[$4]++;}} \
for(i in name){if(stretch[i] in Uiso && Uiso[stretch[i]]>=mTO) \
{print name[i],num[i],nov[i],stretch[i]}} }' > LongReadInfo/tmp

fi


awk 'BEGIN{OFS="\t";} NR==FNR {split($1,a,"@"); \
name[a[2]]=a[2];bc[a[2]]=$5;ct[a[2]]=$7;umi[a[2]]=$8;ensGene[a[2]]=$12;next} \
$1 in name {print $0,bc[$1],ct[$1],ensGene[$1],umi[$1]}' \
LongReadInfo/Mapped_Barcoded LongReadInfo/tmp > LongReadInfo/XX
#ensGene[a[2]]=$9

cat LongReadInfo/XX | awk 'BEGIN {OFS="\t"} {print $1,$7,$6,$5,$8,$4,$3,$2}' > LongReadInfo/AllInfo

rm LongReadInfo/tmp
rm LongReadInfo/XX

cat LongReadInfo/AllInfo | awk '{if(!seen[$2"_"$4]++){count[$4"~"$3]++$2;}}END {for (c in count) \
{split(c,s,"~"); OFS="\t"; {print s[1],s[2],count[c]}}}' > LongReadInfo/GenesPerCell

cat LongReadInfo/AllInfo | awk '{if(!seen[$1"_"$4]++){count[$4"~"$3]++$1;}}END {for (c in count) \
{split(c,s,"~"); OFS="\t"; {print s[1],s[2],count[c]}}}' > LongReadInfo/ReadsPerCell

cat LongReadInfo/AllInfo | awk '{if(!seen[$5"_"$4]++){count[$4"~"$3]++$5;}}END {for (c in count) \
{split(c,s,"~"); OFS="\t"; {print s[1],s[2],count[c]}}}' > LongReadInfo/UMIsPerCell

echo "Output in LongReadInfo"
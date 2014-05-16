#!/bin/bash
hisPath="/home/pixie16/svp/students/pixie_scan/run4024-newTest.his"
tofId=3133
diffId=3132
numBars=36
let numDiff=$numBars-1
let numTof=$numBars-1
let tofLines=$numBars+1
let diffLines=$numBars+1

errorMsg() {
    echo -e "We have some kind of problems fitting the " $1 "."
    echo -e "You should check the fitting script and adjust initial parameters"
}

successMsg() {
    echo -e "FUCK YEAH!!!! We successfully completed the " $1 " fits."
    echo -e "There were " $2 " fits (plus one header line)"
}

#--------- DOING THE TOF PART ----------------
rm -f results-tof.dat test.par test.dat
echo -e "#Num MaxPos Mu" > results-tof.dat
for i in `seq 0 $numTof`
do
    readhis $hisPath --id $tofId --gy $i,$i > test.dat
    hasData=`awk '{if(NR>4 && $2!=0){print 1; exit(1)} }' test.dat`
    gnuplot timingCal.gp 2>&1>/dev/null && j=`cat test.par`
    if (( hasData == 0 ))
    then
        echo $i 0.0 0.0 >> results-tof.dat
    else
        echo $i $j >> results-tof.dat
    fi
done

#--------- DOING THE DIFF PART ---------------
rm -f test.par test.dat results-diff.dat
echo -e "#Num MaxPos Mu" > results-diff.dat
for i in `seq 0 $numDiff`
do
    #readhis $hisPath --id $diffId --gy $i,$i > test.dat
    #hasDiffData=`awk '{if(NR>4 && $2!=0){print 1; exit(1)} }' test.dat`
    #gnuplot timingCal.gp 2>&1>/dev/null && j=`cat test.par`
    #if (( hasDiffData == 0 ))
    #then
        echo $i 0.0 >> results-diff.dat
    #else
    #    echo $i 0.0 >> results-tof.dat
    #fi
done

#---------- CHECK THE NUMBER OF TOF LINES -----------------------
numFits=`awk '{nlines++} END {print nlines}' results-tof.dat`
if (( $numFits != $tofLines ))
then
    errorMsg "TOF"
else
    successMsg "tof" $numFits
fi

#---------- CHECK THE NUMBER OF DIFF LINES ------------------------
numFits=`awk '{nlines++} END {print nlines}' results-diff.dat`
if (( $numFits != $diffLines ))
then
    errorMsg "DIFF"
else
    successMsg "diff" $numFits
fi

#---------------- CALCULATE THE NEW LINES FOR THE CORRECTION -------------
awk '{if (NR > 1) print $1, (620-$3)*0.5}' results-tof.dat > results-tof.tmp
awk '{if (NR > 1) print $1, 0.0}' results-diff.dat > results-diff.tmp

#----------- UPDATE THE TIMING CAL FILE -------------------
while read LINE
do
    barNum=`echo $LINE | awk '{print $1}'`
    cal0=`echo $LINE | awk '{print $2}'`
    cal1=0.0

    newLine=`awk -v bar=$barNum -v tofCal0=$cal0 -v tofCal1=$cal1 '{if($1==bar && $2 =="big")print $1,$2,$3,$4,$5,$6, tofCal0, tofCal1}' timingCal.txt`
    awk -v bar=$barNum -v line="$newLine" '{if($1==bar && $2 =="big") sub($0,line); print}' timingCal.txt > vandleCal.tmp
    mv vandleCal.tmp timingCal.txt
done < results-tof.tmp

while read LINE
do
    set -- $LINE
    barNum=$1
    cal=$2
    
    newLine=`awk -v bar=$barNum -v diffCal0=$cal '{if($1==bar && $2 =="big")print $1,$2,$3,$4,$5,diffCal0,$7,$8}' timingCal.txt`
    awk -v bar=$barNum -v line="$newLine" '{if($1==bar && $2 =="big") sub($0,line); print}' timingCal.txt > vandleCal.tmp
    mv vandleCal.tmp timingCal.txt
done < results-diff.tmp
echo "Finished constructing the timingCal.txt."

echo "Removing the temporary files"
rm -f results-diff.tmp results-tof.tmp fit.log

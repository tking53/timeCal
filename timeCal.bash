#!/bin/bash
#For test00-cut.his we need to look at 3200 as it contains the QDC
#For test00-orig.his we look at the standard 3103
#Either one will use 3102 for the time differences

#numBars=$1
numBars=48
let dubBars=$numBars*2
let numDiff=$numBars-1
let numTof=$dubBars-1
let tofLines=$dubBars+1
let diffLines=$numBars+1

echo $numBars $dubBars

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
touch results-tof.dat && echo -e "#Num MaxPos Mean" >> results-tof.dat
for i in `seq 0 $numTof`
do
    readhis his/cu77-b/test00-cut.his --id 3200 --gy $i,$i > test.dat
    gnuplot timingCal-tof.gp 2>&1>/dev/null && j=`cat test.par`
    echo $i $j >> results-tof.dat
done

#--------- DOING THE DIFF PART ---------------
rm -f test.par test.dat results-diff.dat
touch results-diff.dat && echo -e "#Num MaxPos Mu" >> results-diff.dat
for i in `seq 0 $numDiff`
do
    readhis his/cu77-b/test00-cut.his --id 3102 --gy $i,$i > test.dat
    gnuplot timingCal-diff.gp 2>&1>/dev/null && j=`cat test.par`
    echo $i $j >> results-diff.dat
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
awk '{if (NR > 1) print int($NF*0.5), (203.366-$4)*0.5}' results-tof.dat > results-tof.tmp
awk '{if (NR > 1) print $NF, (200.0-$4)*0.5}' results-diff.dat > results-diff.tmp

#----------- UPDATE THE TIMING CAL FILE -------------------
while read LINE
do
    barNum=`echo $LINE | awk '{print $1}'`
    cal0=`echo $LINE | awk '{print $3}'`
    read LINE
    cal1=`echo $LINE | awk '{print $3}'`
    
    newLine=`awk -v bar=$barNum -v tofCal0=$cal0 -v tofCal1=$cal1 '{if($1==bar && $2 =="small")print $1,$2,$3,$4,$5,$6, tofCal0, tofCal1}' timingCal.txt`
    awk -v bar=$barNum -v line="$newLine" '{if($1==bar && $2 =="small") sub($0,line); print}' timingCal.txt > vandleCal.tmp
    mv vandleCal.tmp timingCal.txt
done < results-tof.tmp

while read LINE
do
    barNum=`echo $LINE | awk '{print $1}'`
    cal=`echo $LINE | awk '{print $3}'`
    
    newLine=`awk -v bar=$barNum -v diffCal0=$cal '{if($1==bar && $2 =="small")print $1,$2,$3,$4,$5,diffCal0,$7,$8}' timingCal.txt`
    awk -v bar=$barNum -v line="$newLine" '{if($1==bar && $2 =="small") sub($0,line); print}' timingCal.txt > vandleCal.tmp
    mv vandleCal.tmp timingCal.txt
done < results-diff.tmp
echo "Finished constructing the timingCal.txt."

echo "Removing the temporary files"
rm -f results-diff.tmp results-tof.tmp

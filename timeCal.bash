#!/bin/bash
#For test00-cut.his we need to look at 3200 as it contains the QDC
#For test00-orig.his we look at the standard 3103
#Either one will use 3102 for the time differences

#numBars=$1
numBars=48
let dubBars=$numBars*2

echo $numBars $dubBars

#rm -f results*.dat test.par test.dat
#touch results-tof.dat && echo -e "#Num MaxPos Mean" >> results-tof.dat
#for i in `seq 0 $dubBars`
#do
#    readhis his/cu77-b/test00-cut.his --id 3200 --gy $i,$i > test.dat
#    gnuplot timingCal.gp && j=`cat test.par`
#    echo $i $j >> results-tof.dat
#done

numFits=`awk '{nlines++} END {print nlines}' results-tof.dat`
echo "Number of Fits for the Time Diff (plus header line) = " $numFits 
if (( $numFits != 97 ))
then
    echo -e "OH FUCK NOOOOOOOOOO!!!!\nWe have some kind of problems fitting the tof."
fi

rm -f test.par test.dat
#touch results-diff.dat && echo -e "#Num MaxPos Mu" >> results-diff.dat
#for i in `seq 0 $numBars`
#do
#    readhis his/cu77-b/test00-cut.his --id 3102 --gy $i,$i > test.dat
#    gnuplot timingCal.gp && j=`cat test.par`
#    echo $i $j >> results-tof.dat
#done

numFits=`awk '{nlines++} END {print nlines}' results-diff.dat`
echo "Number of Fits for the Time Diff (plus header line) = " $numFits 
if (( $numFits != 49 ))
then
    echo -e "OH FUCK NOOOOOOOOOO!!!! We have some kind of problems fitting the time difference."
fi





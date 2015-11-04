#!/bin/bash
#-------------------------------------------------------------------------------
# -- \file timeCal.bash
# -- Description: This is a bash script that will extract the  ToF and Tdiff
# --    spectra from an uncalibrated VANDLE histogram using readhis. It will
# --    give as final output the xml code for the pixie_scan-v3 configuration
# --    file. It expects as input the number of VANDLE bars you have in the
# --    analysis.
# --    
# -- \author S. V. Paulauskas
# -- \date 05 December 2012
# --
# -- This script is distributed as part of a suite to perform
# -- calibrations for VANDLE. It is distributed under the
# -- GPL V 3.0 license. 
# ------------------------------------------------------------------------------
source config.bash

speedOfLight=29.9792458 #cm/ns

let maxStartCount=$numStarts-1
let numSmallCount=$numSmallBars-1
let numMediumCount=$numMediumBars-1
let numBigCount=$numBigBars-1

tempHistData="/tmp/tcal.dat"
tempFitResults="/tmp/tcal.par"
errorLog="errors.log"
rm $errorLog > /dev/null 2>&1
skippedCount=0

SumSpectraCounts() {
    sum=`awk '{if(NR>4){sum += $2}} END{print sum}' $tempHistData`
    if [ $sum -ge $minStats ]
    then
        hasEnoughStats=true
    else
        if [[ $fitType -eq "tof" ]]
        then
            skipped[skippedCount]="ToF : $type $num w/ Start $startNum"
        elif [[ $fitType -eq "diff" ]]
        then
            skipped[skippedCount]="Diff : $type $num"
        else
            echo "We should never have an unknown fit type."
        fi
        let skipCount=skipCount+1
        hasEnoughStats=false
    fi
}

ProjectSpectra() {
    readhis $his --id $histId --gy $row,$row > $tempHistData
    SumSpectraCounts
}

PerformFit() {
    ProjectSpectra
    if [ "$hasEnoughStats" = true ]
    then
        gnuplot timeCal.gp > /dev/null 2>&1 && fitRes=`cat $tempFitResults`
    else
        fitRes=0
    fi
}

CalcGammaTof() {
    gammaTofNs=`echo "$dist/$speedOfLight" | bc -l`
    gammaTofBins=`echo "$gammaTofNs*$histResolution+$histOffset" | bc -l`
}

SetParams(){
    type=$1
    if [ "$type" = small ]
    then
        dist=$smallDist
        offset=$smallOffset
        maxBarCount=$numSmallCount
        numBars=$numSmallBars
        physOffsets=$physOffsetDir/$smallOffsets
    elif [ "$type" = medium ]
    then
        type=medium
        dist=$mediumDist
        offset=$mediumOffset
        maxBarCount=$numMediumCount
        numBars=$numMediumBars
        physOffsets=$physOffsetDir/$mediumOffsets
    elif [ "$type" = big ]
    then
        type=big
        dist=$bigDist
        offset=$bigOffset
        maxBarCount=$numBigCount
        numBars=$NumBigBars
        physOffsets=$physOffsetDir/$bigOffsets
    else
        echo "ERROR: We have gotten an unknown bar type ($type)!! "\
             "This should never happen! Now barfing...."
        exit
    fi
}

CalculateAndOutput(){
    CalcGammaTof
    echo -e "<$type>"
    for j in `seq 0 $maxBarCount`
    do
        num=$j; row=$j
        let histId=$vandleOffset+$vandleTdiffBaseId+$offset
        fitType="diff"
        PerformFit
        if [ "$fitRes" != 0 ]
        then
            fitRes=`echo "scale=5;($histOffset-$fitRes)/$histResolution" | bc -l`
        else
            echo "Warning: Not enough stats for TDiff fit in $type bar $j "\
                 >> $errorLog
        fi

        physInfo=`awk -v barnum=$j '{if($1==barnum) print "z0=\""$2"\" xoffset=\""$3"\" zoffset=\""$4"\""}' $physOffsets`
        echo -e "    <Bar number=\"$j\" lroffset=\"$fitRes\" $physInfo>"
        
        let histId=vandleOffset+vandleTofBaseId+$offset
        for i in `seq 0 $maxStartCount` 
        do
            startNum=$i
            row=`echo "$j*$numStarts+$i" | bc`
            fitType="tof"
            PerformFit
            if [ "$fitRes" != 0 ]
            then
                fitRes=`echo "scale=5;($gammaTofBins-$fitRes)/$histResolution" |bc -l`
            else
                echo "Warning: Not enough stats for ToF fit in $type bar $j "\
                     "and start $i" >> $errorLog
            fi
            echo -e "        <TofOffset location=\"$i\" offset=\"$fitRes\"/>"
        done
        echo -e "    </Bar>"
    done
    echo -e "</$type>"
}

OutputInfo() {
    echo "We are calculating the parameters for $numBars $type Bars."
}

if [[ ! -z $numSmallBars &&  "$numSmallBars" != 0 ]]
then
    SetParams "small"
    OutputInfo
    CalculateAndOutput > $resultDir/smallConfig.xml
fi

if [[ ! -z $numBigBars && "$numBigBars" != 0 ]]
then
    SetParams "big"
    OutputInfo
    CalculateAndOutput > $resultDir/bigConfig.xml
fi

if [[ ! -z $numMediumBars && "$numMediumBars" != 0 ]]
then
    SetParams "medium"
    OutputInfo
    CalculateAndOutput > $resultDir/mediumConfig.xml
fi

if [ -f $errorLog ]
then
    echo "There were errors/warnings written to the error log: $errorLog"
fi

rm -f ./fit.log /tmp/tcal.*

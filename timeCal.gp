#-----------------------------------------------------------------
# -- \file timingCal.gp
# -- Description: This is a gnuplot script to find the maximum of
# --    a distribution, do a simple Gaussian fit, and then
# --    output the results of that fit to a text file. It is
# --    intended to be used in conjunction with timeCal.bash.
# --    
# -- \author S. V. Paulauskas
# -- \date 05 December 2012
# --
# -- This script is distributed as part of a suite to perform
# -- calibrations for VANDLE. It is distributed under the
# -- GPL V 3.0 license. 
# ---------------------------------------------------------------
reset
set fit errorvariables
set terminal dumb
file="/tmp/tcal.dat"

plot file u 1:2
max = GPVAL_DATA_Y_MAX

plot file u ($2 == max ? $2 : 1/0):1
max_pos_x = GPVAL_DATA_Y_MAX

fitLow=max_pos_x-30
fitHigh=max_pos_x+30

gaussian(x) = (amp/(sigma*sqrt(2*pi)))*exp(-(x-mu)**2/(2*sigma**2))
sigma=2.7
amp=max*sqrt(2*pi)*sigma
mu=max_pos_x
fit [fitLow:fitHigh] gaussian(x) file u 1:($2 > 0 ? $2 : 1/0):3 via amp,sigma,mu
mu=mu+0.5

set print "/tmp/tcal.par"
print mu
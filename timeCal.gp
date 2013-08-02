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
set xrange[180:250]
set fit errorvariables
set terminal dumb
file="test.dat"

gaussian(x) = (amp/(sigma*sqrt(2*pi)))*exp(-(x-mu)**2/(2*sigma**2))

num = 0
max = 0.0
max_pos = 0
max_pos_x = 0
f(x,y) = ((max < y ? (max = y, max_pos_x = x, max_pos = num) : 1), num = num+1,  y)
plot file using 1:(f($1, $2))

amp=max*5
sigma=2.7
mu=max_pos
fit gaussian(x) file u 1:($2 > 0 ? $2 : 1/0):3 via amp,sigma,mu
mu=mu+0.5

set print "test.par"
print max_pos, mu
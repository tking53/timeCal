reset
#load "/home/vincent/.gnuplot"
set terminal dumb
#set terminal wxt enhanced
file="test.dat"

low=979
high=1008

set xrange[low:high]
stats [low:high] file using 1:2 name "test"
set print
print test_index_max_y, test_max_y

amp=test_max_y
sigma=1.
mu=test_index_max_y+979
y0 = test_mean_y
#gaussian(x) = #put normalized gausisan equation here

f(x) = gaussian(x) + y0
fit f(x) file u 1:2:3 via amp,sigma,mu,y0
mu=mu+0.5

plot file using 1:2 w steps, f(x)

set print "test.par"
print test_index_max_y+979, mu
#pause 4
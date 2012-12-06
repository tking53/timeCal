reset
set xrange[150:250]
set fit errorvariables
set terminal dumb
#file="his/cu77-b/testDiff11.dat"
file="test.dat"

num = 0
max = 0.0
max_pos = 0
max_pos_x = 0
f(x,y) = ((max < y ? (max = y, max_pos_x = x, max_pos = num) : 1), num = num+1,  y)
plot file using 1:(f($1, $2))

#EMG
amp=max*10
sigma=3.
mu=max_pos

fit gaussian(x) file u 1:($2 > 0 ? $2 : 1/0):3 via amp,sigma,mu

set arrow from mu+0.5,0 to mu+0.5,max nohead lc 3
set print "test.par"
print max_pos, mu+0.5, max
plot file w steps, gaussian(x-0.5)
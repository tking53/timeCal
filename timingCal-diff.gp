reset
set xrange[220:229]
set fit errorvariables
set terminal wxt 1

file="his/cu77-b/testcut82.dat"
file="test.dat"

num = 0
max = 0.0
max_pos = 0
max_pos_x = 0
f(x,y) = ((max < y ? (max = y, max_pos_x = x, max_pos = num) : 1), num = num+1,  y)
plot file using 1:(f($1, $2))

#EMG
amp=max*5
sigma=2.
mu=max_pos

fit gaussian(x) file u 1:($2 > 0 ? $2 : 1/0):3 via amp,sigma,mu

mean=mu+1/lambda
skew=(2/sigma**3/lambda**3)*(1+1/sigma**2/lambda**2)**(-3/2)
ave=0.5*(mean+mu)

set arrow from mu+0.5,0 to mu+0.5,max nohead lc 3
#set arrow from x0,0 to x0,max nohead lc 5
#set print "test.par"
print max_pos, mu
#print max_pos, mu, mean, skew, ave
plot file w steps, gaussian(x-0.5)
reset
set xrange[180:250]
set fit errorvariables

#file="his/cu77-b/testcut79.dat"
file="test.dat"

num = 0
max = 0.0
max_pos = 0
max_pos_x = 0
f(x,y) = ((max < y ? (max = y, max_pos_x = x, max_pos = num) : 1), num = num+1,  y)
plot file using 1:(f($1, $2))

#EMG
amp=max*5
lambda=1.5
sigma=2.7
mu=max_pos
emg(x)=amp*0.5*lambda*exp(0.5*lambda*(2*mu+lambda*sigma**2-2*x))*erfc((mu+lambda*sigma**2-x)/(sqrt(2)*sigma))

fit emg(x) file u 1:($2 > 0 ? $2 : 1/0):3 via amp,sigma,mu,lambda

mean=mu+1/lambda
skew=(2/sigma**3/lambda**3)*(1+1/sigma**2/lambda**2)**(-3/2)

set print "test.par"
print max_pos, mean

set arrow from mean,0 to mean,max nohead
plot file w steps, emg(x-0.5)
#pause 0.5

#setwd("~/Papers/NormalDynamic")
library(ocp )
library(ggplot2)
set.seed(15)
#--------------------- set_up --------------------------
number_states = 15
number_Trials = 10000
reference_mean = 20
average_interval = 50
df_chi =1.5
#--------------------- calc ---------------------
reevalutation_step = 1000
distribution_means = rnorm( number_states , 
                            reference_mean+rnorm(number_states ,0, 2), #pmax(rchisq(number_states, df_chi),0.5)) ,
                            vector("double", number_states)+0.2)#pmax(rchisq(number_states, 1/5*df_chi),0.5 ) )
distribution_variances = vector("double", number_states)+0.2#pmax(1/5*rchisq(number_states, df_chi), 0.5)
pois_draws = round(2*number_Trials/round(average_interval/2,0),0)
pois_parameters = rpois(pois_draws,average_interval)+1
interval_lengths = rpois(round(pois_draws), pois_parameters)
while(sum(interval_lengths)<(number_Trials+2)){
  pois_parameters = rpois(pois_draws,average_interval)+1
  interval_lengths = rpois(round(pois_draws), pois_parameters)
}
discrete_grid = 1/number_states*(0:number_states)
generators = runif(length(interval_lengths))
state_chain = vector("double", length(interval_lengths))
for(i in 1:length(interval_lengths)){
  state_chain[i] =  sum(as.numeric(generators[i]>discrete_grid))
}

Observations = {}
#Generate Data
for(i in 1:length(interval_lengths)){
  Observations = c(Observations, rnorm(interval_lengths[i],
                                       distribution_means[state_chain[i] ],
                                       distribution_variances[state_chain[i] ] ) )
}


NLL_norm = function(x,m,s){
  fun_val = -1/2*log(2*pi)-log(s)-(x-m)^2/(2*s^2)
  fun_val = -fun_val
    return(fun_val)
}
T_norm = function(x,m,s){
  fun_val = {}
  for(i in 1:length(x)){
    fun_val[i] =  min( 1.0 - pnorm(x[i],m,s), pnorm(x[i],m,s) )
    fun_val[i] = -log(fun_val[i] )
  }
  return(fun_val)
}
#

w0 =1
w1 = 30
mu = 20
Values = Observations
mu_multi_track = vector("double", length(Observations)+1)
mu_single_track = vector("double", number_Trials+1)
mu_log_track = vector("double", length(Observations)+1)
mu_NLL_track = vector("double", length(Observations)+1)
mu_t_track = vector("double", length(Observations)+1)
mu_single_track[1] =mu
update_index = 1
for(i in 1:number_Trials){
  update_index = update_index+1
  mu_single_track[i+1] = (update_index-1)/update_index*mu_single_track[i]+1/update_index*Values[i]
}
Basic_error = sqrt(sum( (mu_single_track[1:(length(mu_single_track)-1)]-Values[1:number_Trials] )^2))

Measured_error = {}
Interesting_error = {}


OC_track=mu
ptm <- proc.time()
OC=onlineCPD(Values[1:number_Trials], hazard_func = function(x, lambda) {     const_hazard(x, lambda = 50)
}, init_params = list(list(m = mu, k = 0.01, a #k=0.01 a=0.01
                            = 0.01, b = 1e-04)) )
#OC <- initOCPD(1, init_params = list(list(m = mu, k = 0.01, a #k=0.01 a=0.01
#                                                 = 0.01, b = 1e-04)))
#OC_test
OC_single_track = vector("double", number_Trials+1)
update_index = 1
OC_single_track[1] =mu
for(i in 1:number_Trials){
  ##OC_single_track[i] = currmu[[i]]
  if(i %in% OC$changepoint_lists$threshcps[[1]]){
    update_index =1
    OC_single_track[i+1] = Values[i]
    
  }else{
    update_index = update_index+1
    OC_single_track[i+1] = (update_index-1)/update_index*OC_single_track[i]+1/update_index*Values[i]

  }
  
  
}
OC_error = sqrt(sum( (OC_single_track[1:(length(OC_single_track)-1)]-Values[1:number_Trials] )^2))

Reference_error={}
Reference_track = vector("double", number_Trials+1)
Reference_track[1]=mu
switches = c(1, cumsum(interval_lengths)+1)
update_index = 1
for(i in 1:number_Trials ){
  if(i %in% switches){
    update_index =1
    Reference_track[i+1] = Values[i]    
    
  }else{
    update_index = update_index+1
    Reference_track[i+1] = (update_index-1)/update_index*Reference_track[i]+1/update_index*Values[i]
    
  }
}
Reference_error = sqrt(sum( (Reference_track[1:(length(Reference_track)-1)]-Values[1:number_Trials] )^2))

L_path = function(y){
print(proc.time() - ptm)
for(w in w0:w0){
  log_thres = abs(y)
  ptm <- proc.time()
  window = w
  update_index = 1
  shift_counter = 0
  state_list = mu
  update_index_list=1
  mu_log_track[1] =mu

  for(i in 1:number_Trials){
    update_index = update_index+1
    mu_log_track[i+1] = (update_index-1)/update_index*mu_log_track[i]+1/update_index*Values[i]

    if( ( NLL_norm( Values[i], mu_log_track[i+1] , 0.2 ) - NLL_norm( Values[i], Values[i] , 0.2 ) ) > (log_thres ) ){
      update_index = 1
      mu_log_track[i+1] =  Values[i]        
      
    }
  }

  Log_error=sqrt(sum( (mu_log_track[1:(number_Trials)]-Values[1:number_Trials] )^2))
  print(proc.time() - ptm)
}
return(Log_error)
}

OpL = optim(c(5), L_path, method = "Brent", 
            control = list(maxit = 20000) , 
            lower= 0.00001, upper = 200)

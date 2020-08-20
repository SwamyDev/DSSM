library(ocp )
library(ggplot2)
library(glue)
set.seed(15)
#--------------------- set_up --------------------------
number_states = 15
number_Trials = 10000
reference_mean = 20
average_interval = 50
#--------------------- calc ---------------------
reevalutation_step = 1000
distribution_means = rnorm( number_states ,
                            reference_mean+rnorm(number_states ,0, 2),
                            vector("double", number_states)+0.2)
distribution_variances = vector("double", number_states)+0.2
pois_draws = round(2*number_Trials/round(average_interval/2,0),0)
pois_parameters = rpois(pois_draws,average_interval)+1
interval_lengths = rpois(round(pois_draws), pois_parameters)
while(sum(interval_lengths)<(number_Trials+2)){
  pois_parameters = rpois(pois_draws,average_interval)+1
  interval_lengths = rpois(round(pois_draws), pois_parameters)
}

# generate mapping from interval index to state (mean & variance)
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

print(length(Observations))
fp <- file("resources/observations.txt")
writeLines(paste(Observations, collapse = "\n"), fp)
close(fp)

#to do: test for new, stabilised and concluded
#
#------------------ estimation block ------------------
cost = 0
w0 =1
w1 = 30
mu = 20

# tracks the estimates means to be able to plot them
mu_multi_track = vector("double", length(Observations)+1)
mu_single_track = vector("double", number_Trials+1)
mu_single_track[1] =mu

# basic basian observer model
update_index = 1
for(i in 1:number_Trials){
  update_index = update_index+1
  mu_single_track[i+1] = (update_index-1)/update_index*mu_single_track[i]+1/update_index*Observations[i]
}

# mean squard error of basic basian observer
Basic_error = sqrt(sum( (mu_single_track[1:(length(mu_single_track)-1)]-Observations[1:number_Trials] )^2))

print(glue("basic mse: {Basic_error}"))

Measured_error = {}
# there used to be different window lengths - currently w1-w0+1 == 1
all_tracks = matrix(0.0, w1-w0+1, length(Observations)+1)
distance_thres = 0.63 # Kappa in the paper - retrieved from optimizer - could be coupled to varince estimate

# online basian change point detection
OC_track=mu # starting value - so mu is same for all
ptm <- proc.time()
OC=onlineCPD(Observations[1:number_Trials], hazard_func = function(x, lambda) {     const_hazard(x, lambda = 50)
}, init_params = list(list(m = mu, k = 0.01, a = 0.01, b = 1e-04))) #k=0.01 a=0.01
#OC_test
OC_single_track = vector("double", number_Trials+1)
update_index = 1
OC_single_track[1] =mu
for(i in 1:number_Trials){

  if(i %in% OC$changepoint_lists$threshcps[[1]]){ # OCP detected a change point
    update_index =1
    OC_single_track[i+1] = Observations[i]

  }else{  # otherwise update our basian observer with new data
    update_index = update_index+1
    OC_single_track[i+1] = (update_index-1)/update_index*OC_single_track[i]+1/update_index*Observations[i]

  }

  # Should work also online, but doesn't hence commented out let's give it a try
  #OC_Val = matrix(Observations[i], 1,1)
  #cVal = OC_Val#Observations[i]
  #OC = onlineCPD(cVal,oCPD=OC)
  #OC=onlineCPD(Observations[1:i], hazard_func = function(x, lambda) {     const_hazard(x, lambda = 50)}, init_params = list(list(m = mu, k = 0.01, a #k=0.01 a=0.01
  #                           = 0.01, b = 1e-04)) )
  #OC_track[i] = OC$currmu[[i]]

}
# mean squared error of OCP to value data
OC_error = sqrt(sum( (OC_single_track[1:(length(OC_single_track)-1)]-Observations[1:number_Trials] )^2))

print(proc.time() - ptm)
print(glue("OC mse: {OC_error}"))

# FAM implementation
for(w in w0:w0){  # NOTICE w0:w0 -> window -> 1
  ptm <- proc.time()
  window = w  # currently 1 and is not used
  update_index = 1
  shift_counter = 0
  state_list = mu
  update_index_list=1
  mu_multi_track[1] =mu

  # old window system - to start when enough data has arrived
  #for(i in 1:window){
  #  update_index = update_index+1
  #  mu_multi_track[i+1] = (update_index-1)/update_index*mu_multi_track[i]+1/update_index*Observations[i]
  #}

  for(i in 1:number_Trials){
    update_index = update_index+1
    # basian observer update
    mu_multi_track[i+1] = (update_index-1)/update_index*mu_multi_track[i]+1/update_index*Observations[i]

    if( sqrt((mu_multi_track[i]-Observations[i])^2) > distance_thres ){ # change point detected!
      shift_counter = shift_counter+1
      update_index = 1
      mu_multi_track[i+1] =  Observations[i]
      provisionary_counter = 0
    }
  }

  all_tracks[w-w0+1, ] = mu_multi_track # would add track into its specific window track -> now this is just 1

  # mean squared error of FAM - currently cost is 0 and shift cost is not used
  Measured_error[w-w0+1]=cost*shift_counter+sqrt(sum( (mu_multi_track[1:(number_Trials)]-Observations[1:number_Trials] )^2))

  print(proc.time() - ptm)
  print(glue("FAM mse: {Measured_error[w-w0+1]}"))
}

# Plotting logic - plot a nice window
# Main figure with legend
fp <- file("resources/sim_y-5000.txt", open = "r");
hgf_lines <- readLines(fp)
close(fp)

hgf_u <- as.numeric(unlist(hgf_lines))

For_plotting = data.frame(cbind(t(t((1:200))), t(t(Observations[1:200]))))
For_drawing = data.frame(cbind(t(t((1:200))), t(t(all_tracks[1, 1:200])),
                               #t(t(Observations[1:200] ) ),
                               t(t(OC_single_track[1:200])),
                               t(t(mu_single_track[1:200])),
                               t(t(hgf_u[1:200]))))
names(For_plotting) = c("Time" ,"Observations"
                         )
names(For_drawing) = c("Time" ,"State_Adaptor",
                        "Bayes_Adaptor", "Basic_Bayes_Observer", "HGF_Adaptor" )

library(reshape2)
dd = melt(For_drawing, id=c("Time"))
ggplot(dd )+
  geom_line(aes(x=Time, y=value, colour = variable, linetype =  variable) )


#+scale_colour_manual(values=c("red","green","blue"))
names(dd) = c("Time", "Model", "value")
gg=ggplot(For_plotting, aes(x= Time, y=Observations))+
  geom_point(shape = 18, colour ="blue" ) +
  geom_line(data = dd, aes(x=Time, y=value, colour = Model,
                           linetype =  Model) , size = 1.2 )+
  labs(title="Mean Adaptation Dynamics", subtitle = "by Model" )+
  theme(plot.title = element_text(hjust = 0.5),
        plot.subtitle = element_text(hjust = 0.5))
pdf(file= "Adaptation.pdf", width = 9)#, width = 800, height = 600, pointsize =3
gg
dev.off()

# For graphical abstract - just the 100 without a legent
For_title_plotting = data.frame(cbind(t(t( (1:100) ) ), t(t(Observations[1:100] ) ) ) )
For_title_drawing = data.frame(cbind(t(t( (1:100) ) ), t(t(all_tracks[1,1:100]) ) ,
                               #t(t(Observations[1:200] ) ),
                               t(t( OC_single_track[1:100] )  ) ,
                               t( t( mu_single_track[1:100] ) )  ) )
names(For_title_plotting) = c("Time" ,"Observations"
)
names(For_title_drawing) = c("Time" ,"State_Adaptor",
                       "Bayes_Adaptor", "Basic_Bayes_Observer" )

library(reshape2)
dd_title = melt(For_title_drawing, id=c("Time"))
names(dd_title) = c("Time", "Model", "value")
gg_title=ggplot(For_title_plotting, aes(x= Time, y=Observations))+
  geom_point(shape = 18, colour ="blue", size = 5 ) +
  geom_line(data = dd_title, aes(x=Time, y=value, colour = Model,
                           linetype =  Model) , size = 1.2 )+
  theme(legend.position = "none")#+
pdf(file= "title_adapt.pdf", width = 9) #, width = 800, height = 600, pointsize =12
gg_title
dev.off()


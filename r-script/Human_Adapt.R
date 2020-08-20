w0 = 1
w1 = 20

Delta_Crit = function(y){
  #print(y)
  Measur = vector("double", w1-w0+1)+1000000
  distance_thres = abs(y)
  #print(distance_thres)
  #print(proc.time() - ptm)
  for(w in w0:w1){
    #ptm <- proc.time()
    update_index = 1

    update_index_list=1
    mu_multi_track[1] =mu
    reference_point = 1

    for(i in 1:number_Trials){
      update_index = update_index+1
      mu_multi_track[i+1] = (update_index-1)/update_index*mu_multi_track[i]+1/update_index*Values[i]
      Change_Point = FALSE
      w_test = w
      #for(w_test in 1:w ){
      #  if(!(Change_Point)){
          window_elements = unique( pmax( ( (i-w_test+1):i ) ,reference_point ) )
          mu_est = replicate(length(window_elements) , mu_multi_track[i+1])
          distance = sqrt(sum( (mu_est-Values[window_elements])^2) ) 
          Change_Point = (distance > distance_thres)
      #  }
        
      #}
      if( Change_Point ){
        #print("changed")
        reference_point = i
        update_index = 1
        mu_multi_track[i+1] =  Values[i]     
      }
      
    }
    
    Measur[w-w0+1]=sqrt(sum( (mu_multi_track[1:(number_Trials)]-Values[1:number_Trials] )^2))
    #print(proc.time() - ptm)
  }
  Best_error = min(Measur)
  #print(which.min(Measur))
  return(Best_error)
}

#Op = optim( 0.4 , Delta_Crit, method = "Brent", 
#           control = list(maxit = 20000) , 
#           lower= 0.00001, upper = 0.9)

Delta_Path = function(y, extr_w, update_speed, mix_ratio ){
  #print(y)
  up = floor(update_speed)
  Measur = vector("double", w1-w0+1)+1000000
  distance_thres = abs(y)
  #print(distance_thres)
  #print(proc.time() - ptm)
  for(w in w0:w1){
    #ptm <- proc.time()
    update_index = up
    mu_multi_track[1] =mu
    reference_point = 1
    
    for(i in 1:number_Trials){
      update_index = update_index+1
      mu_multi_track[i+1] = (update_index-1)/update_index*mu_multi_track[i]+1/update_index*Values[i]
      Change_Point = FALSE
      w_test = w
      #for(w_test in 1:w ){
      #  if(!(Change_Point)){
      window_elements = unique( pmax( ( (i-w_test+1):i ) ,reference_point ) )
      mu_est = replicate(length(window_elements) , mu_multi_track[i+1])
      distance = sqrt(sum( (mu_est-Values[window_elements])^2) ) 
      Change_Point = (distance > distance_thres)
      #  }
      
      #}
      if( Change_Point ){
        #print("changed")
        reference_point = i
        update_index = up
        mu_multi_track[i+1] = (1.0-mix_ratio)*mu_multi_track[i+1] +(mix_ratio)*Values[i]     
      }
      
    }
    
    Measur[w-w0+1]=sqrt(sum( (mu_multi_track[1:(number_Trials)]-Values[1:number_Trials] )^2))
    if(w== extr_w){
      Output_track = mu_multi_track[1:(number_Trials)]
    }
    #print(proc.time() - ptm)
  }
  #Best_error = min(Measur)
  #print(which.min(Measur))
  return(Output_track)
}

result_track = Delta_Path(0.9, 5, 1 , 1)
slow_adapt_track = Delta_Path(0.9, 5, 5 , 0.5)
higherthres_track = Delta_Path(2.0, 5, 1 , 1)
higherthres_slow_track = Delta_Path(2.0, 5, 5 , 0.5)

result_track = Delta_Path(0.9, 5, 1 , 1)
slow_adapt_track = Delta_Path(0.9, 5, 5 , 0.5)
higherthres_track = Delta_Path(2.0, 5, 1 , 1)
higherthres_slow_track = Delta_Path(2.0, 5, 5 , 0.5)

plot(Values[1:100], col = "blue", bty= 'n', xlab = "Time", ylab = "Value")
lines(result_track[1:100], col = "orange")
lines(higherthres_slow_track[1:100], col = "green")
lines(higherthres_track[1:100], col = "red")
lines(slow_adapt_track[1:100], col = "skyblue")
legend("topright", col = c("orange", "green", "red", "skyblue") , 
legend = c( "Reference Model" , "High Threshold, Slow Adaptation", "High Threshold", "Slow Adaptation"), 
lty = c(1,1,1,1)  )
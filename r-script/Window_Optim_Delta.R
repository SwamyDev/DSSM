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
  print(which.min(Measur))
  return(Best_error)
}

Op = optim( 0.4 , Delta_Crit, method = "Brent", 
           control = list(maxit = 20000) , 
           lower= 0.00001, upper = 0.9)

#w1 = 6

NLL_Crit = function(y){
  #print(y)
  Measur = vector("double", w1-w0+1)+1000000
  NLL_thres = abs(y)
  #print(distance_thres)
  #print(proc.time() - ptm)
  for(w in w0:w1){
    #ptm <- proc.time()
    update_index = 1
    reference_point = 1
    update_index_list=1
    mu_multi_track[1] =mu
    mu_est = mu
    #window_elements = 1
    for(i in 1:number_Trials){
      update_index = update_index+1
      
           
      #mu_multi_track[i+1] = (update_index-1)/update_index*mu_multi_track[i]+1/update_index*Values[i]
      
      Change_Point = FALSE
      #for(w_test in 1:w ){
      #  if(!(Change_Point)){
      #window_elements = unique( pmax( ( (i-w_test+1):i ) ,reference_point ) ) 
      #    mu_est = mean(Values[window_elements]) #replicate(length(window_elements) , mu_multi_track[i+1])
          s_est = 0.2#replicate(length(window_elements), 0.2)
          #mu_multi_track[i+1] = mean(Values[window_elements])
          distance =  NLL_norm(Values[i], Values[i],0.2) - NLL_norm(Values[i] ,mu_est,s_est)   
          Change_Point = (distance > NLL_thres)
      #  }
        
      #}
      if( Change_Point ){
        reference_point = i
        update_index = 1
        mu_multi_track[i+1] =  Values[i]   
        mu_est = Values[i]
      }else{
        window_elements = unique( pmax( ( (i-w+1):i ) ,reference_point ) ) 
        mu_est = mean(Values[window_elements])
        mu_multi_track[i+1] = mu_est
      }
      
    }
    
    Measur[w-w0+1]=sqrt(sum( (mu_multi_track[1:(number_Trials)]-Values[1:number_Trials] )^2))
    #print(proc.time() - ptm)
  }
  Best_error = min(Measur)
  print(which.min(Measur))
  return(Best_error)
}

Opo = optim( 2 , NLL_Crit, method = "Brent", 
            control = list(maxit = 20000) , 
            lower= 0.00001, upper = 15)

RW_tracker = function(y){
  adapt_rate = abs(y)
  mu_multi_track[1] =mu
  
  for(i in 1:number_Trials){
    mu_multi_track[i+1] = mu_multi_track[i]+adapt_rate*(Values[i]-mu_multi_track[i])
  }
  
  Measur=sqrt(sum( (mu_multi_track[1:(number_Trials)]-Values[1:number_Trials] )^2))
  
  return(Measur)
}
Op_RW = optim( 0.5 , RW_tracker, method = "Brent", 
             control = list(maxit = 20000) , 
             lower= 0.00001, upper = 1)

T_path = function(y){
  T_thres = abs(y)
  Measur = vector("double", w1-w0+1)+1000000
  for(w in w0:w1){
    update_index = 1
    mu_t_track[1] =mu
    reference_point = 1
    for(i in 1:number_Trials){
      update_index = update_index+1
      mu_t_track[i+1] = (update_index-1)/update_index*mu_t_track[i]+1/update_index*Values[i]
      Change_Point = FALSE
      w_test = w
      #for(w_test in 1:w ){
      #  if(!(Change_Point)){
          window_elements = unique( pmax( ( (i-w_test+1):i ) ,reference_point ) )
          distance = sum(T_norm( Values[window_elements], mu_t_track[i+1] , 0.2 ) )
          Change_Point = (distance > T_thres)
      #  }
        
      #}
      if( Change_Point ){
        reference_point = i
        update_index = 1
        mu_t_track[i+1] =  Values[i]     
      } 
      

    }
    Measur[w-w0+1]=sqrt(sum( (mu_t_track[1:(number_Trials)]-Values[1:number_Trials] )^2))
  }
    Best_error = min(Measur)
    print(which.min(Measur))
    return(Best_error)
  
}

OpT = optim(c(11), T_path, method = "Brent", 
            control = list(maxit = 20000) , 
            lower= 0.00001, upper = 50)
input_T = OpT$par


# dataclean function
dataclean <- function(filepath){
  library(plyr)
  # read .csv in filepath
  readwks <- function(file) {
    filenames <- list.files(path = file, pattern = "*.csv", full.names = TRUE)
    ldply(filenames, .fun = read.csv)
  }
  a <- readwks(filepath)
  #count stock number 
  num_stocks <- length(list.files(path = filepath, pattern = "*.csv"))
  # output stock name
  name_stocks.csv <- list.files(path = filepath, pattern = "*.csv")
  name_stocks <- substr(basename(name_stocks.csv), 1, nchar(basename(name_stocks.csv)) - 4) 
  # construct data output matrix with date and stock name
  b <- matrix(a[,"Adj.Close"], nrow = nrow(a)/num_stocks, ncol = num_stocks)
  date <- a[1:(nrow(a)/num_stocks),'Date']
  rownames(b) <- date
  colnames(b) <- name_stocks
  return(b)
}
library(quantmod)
data=dataclean("~/test/test")

for (i in 1:length(data[1,])){
  data[,i] <- dailyReturn(data[,i])  # Daily return
}



PCA <- function(Variance,data) {
  pcax <- prcomp(data)  # PCA
  vars <- apply(pcax$x,2,var)
  props <- vars / sum(vars)  # Var propotion of each PC
  cumprops <- cumsum(props)  # Cum Var propotion
  k <- 5
  for (i in 5:(length(cumprops)-1))
    if ((cumprops[i] < Variance) & ((cumprops[i+1] > Variance)))
      k <- i+1
  w=pcax$rotation[,1:k]
  return(list(PCw = w , K = max(k,5)))  # pick PCs makes %Variance variance
}

Regression <- function(i,t,x,PCw,data) { # regression target port. aginst Picked PCs previously
  Rtn <- data[(i-t):(i-1),]%*%PCw
  Reg <- lm(x[(i-t):(i-1)] ~ Rtn)
  return(list(res = Reg$residuals , coef = Reg$coefficients))  # Return residuals for Time Series Analysis
}

AR_1 <- function(res) {    # fits AR(1) model
  est <- arima(res,order = c(1,0,0),include.mean = FALSE,method = "ML")
  return(c(est$coef,est$sigma2))   # Return Est. Phi and sigma^2
}

Signal_cal <- function(x_i,phi,var,i,beta,beta0,Rtn_i) {  #Signal Calculation
  k <- -log(abs(phi))
  sigma <- sqrt(var/(1-phi^2))  # Est of std deviation of residuals
  m <- beta0+Rtn_i%*%beta
  signal <- (x_i-m)/sigma
  return(signal)
}


Dailyrtn <- function(i,PCw,beta,beta0,y,data,sgn) {   # CAlculate everyday return
  m <- (data[i,]%*%PCw)%*%beta+beta0    # m: model return, x: target port. return
  Dr <- sgn*(y[i]-m)       # Daily return
  
  return(Dr)
}



startdate <- 2000   # start date   # same period for back test and refinement!
enddate <- 4000    # end date      # Time: 2006/1/1 - 2013/12/31
period_PCA <- 500  # Time frame for PCA (using 500 days' data before day i)
period_reg <- 60   # Time frame for regression (using 60 records before day i)
var_prop <- 0.55   # PCs with 60% variance
trans <- 0.0001   # transcation cost

FLAG1 <- FALSE    # identify if we have position
LONG <- FALSE     # identify Long/short of the position
FLAG2 <- TRUE     # identify if we need to redo PCA

data_I <- data[,1:200]  # Stocks we use to build model

NumPCA <- rep(0,5000)   # Record the number of PCs

SS <- rep(1,5000)
Dr <- rep(0,5000)
backtest <- data[,c(301,306,307,313,314,319,323,327,329,331,333,335,338,339,
                    345,350,351,352,364,369,372,377,380,381,392)]    # target stock for back test
refinement <- data[,c(396,397,399,403,406,407,421,432,434,435,436,440,442,443,445,447,449)]   # target stock for refinement

SSb <- matrix(1,ncol = length(backtest[1,]),nrow = 5000) # record cumulative return 
Drb <- matrix(0,ncol = length(backtest[1,]),nrow = 5000) # record daily return
var1b <- matrix(0,ncol = length(backtest[1,]),nrow = 5000)  # record estimate var of error for regression

SSr <- matrix(1,ncol = length(refinement[1,]),nrow = 5000) # record cumulative return 
Drr <- matrix(0,ncol = length(refinement[1,]),nrow = 5000) # record daily return
var1r <- matrix(0,ncol = length(backtest[1,]),nrow = 5000)  # record estimate var of error for regression


for (j in 1:length(refinement[1,])){
  x <- refinement[,j]
  # x <- refinement[,j]
  for (i in startdate:enddate){
    if (FLAG2 == TRUE){
      PCw <- PCA(var_prop,data_I[(i-period_PCA):(i-1),])[[1]]  # initalize PCA every 180 days/after closing out position
      k <- PCA(var_prop,data_I[(i-period_PCA):(i-1),])[[2]]
      t0 <- i
    }
    NumPCA[i] <- k
    FLAG2 <- FALSE
    if ((i-t0) >= 180)        # if no position enrolled in previous 180 days, redo PCA next time
      FLAG2 <- TRUE
    
    if (FLAG1 == FALSE){      # we donlt have position now
      
      res <- Regression(i,period_reg,x,PCw,data_I)[[1]]   # indentify residule of regression
      coef <- Regression(i,period_reg,x,PCw,data_I)[[2]]  
      beta0 <- coef[1]    # intercept of regression
      beta <- coef[2:length(coef)]   # beta of each PC
      
      phi <- AR_1(res)[[1]]     # est. of phi
      var <- AR_1(res)[[2]]     # est. of sigma^2
      
      FLAG <- TRUE             # Regression with large VAR of Error    
      if (sqrt(var) > 0.33){
        FLAG <- FALSE
      }
      
      Rtn_i <- data_I[i,]%*%PCw    # PCs' return
      signal <- Signal_cal(x[i],phi,var,i,beta,beta0,Rtn_i)
      if ((abs(signal) > 2) & (FLAG == TRUE)){
        FLAG1 <- TRUE
        t1 <- i
        if (signal>2){   # Judge Long or Short
          LONG <- FALSE
          sgn <- -1      # For daily return calculation//signal weighting
        }     
        else{
          sgn <- 1     # For daily return calculation//signal weighting
          LONG <- TRUE
        } 
      }
      
      Drr[i,j] <- 0   # for backtest, no transaction cost
      SSr[i,j] <- SSr[i-1,j]    # record simulated return
      
      if (FLAG1 == TRUE){  # for refinement, with transaction cost
        if (LONG == TRUE){  # open long position, sell PCs will cause transaction cost 
          Drr[i,j] <- -trans*sum(abs(PCw%*%beta))   
          SSr[i,j] <- SSr[i-1]*(1+Drr[i])     # record simulated return
        }
        else{               # open short position, sell target stock will cause transaction cost
          Drr[i,j] <- -trans   
          SSr[i,j] <- SSr[i-1]*(1+Drr[i])     # record simulated return
        }
      }
    }
    else{                  # we have position now
      FLAG2 <- FALSE    # don't want to change PCs when we have position
      signal <- Signal_cal(x[i],phi,var,i,beta,beta0,Rtn_i)
      
      if (LONG == TRUE){     # LONG/SHORT Position stop game judgement
        if ((signal < -5)|(signal > 2)|(i-t1 >= 90)){
          FLAG1 <- FALSE    # close out position
          FLAG2 <- TRUE     # need to redo PCA after closing out
        }
      }
      else{
        if ((signal < -2)|(signal > 3)|(i-t1 >= 90)){
          FLAG1 <- FALSE    # close out position
          FLAG2 <- TRUE     # need to redo PCA after closing out
        }
      }
      
      Drr[i,j] <- Dailyrtn(i,PCw,beta,beta0,x,data_I,sgn)   # for backtest, no transaction cost
      SSr[i,j] <- SSr[i-1]*(1+Drr[i,j])     # record simulated return
      
      if (FLAG1 == FALSE){  # for refinment, with transaction cost
        if (LONG == FALSE){  # close out short position, sell PCs will cause transaction cost 
          Drr[i,j] <- Dailyrtn(i,PCw,beta,beta0,x,data_I,sgn) - trans*sum(abs(PCw%*%beta))   
          SSr[i,j] <- SSr[i-1]*(1+Drr[i])     # record simulated return
        }
        else{              # close out long position, sell target stock will cause transaction cost
          Drr[i,j] <- Dailyrtn(i,PCw,beta,beta0,x,data_I,sgn) - trans   
          SSr[i,j] <- SSr[i-1]*(1+Drr[i])     # record simulated return
        }
      }
    }
    
    var1r[i,j] <- var
    
    # var1r[i,j] <- var
  }
  print(c(j,SSr[enddate,j]))
  plot(SSr[startdate:enddate,j])
}

# Data Present
library(moments)
Eq_Drb <- rowMeans(Drb[startdate:enddate,])
Eq_SSb <- rowMeans(SSb[startdate:enddate,])   # PLOT!
Eq_varb <- rowMeans(var1b[startdate:enddate,]) # PLOT!

min(SSb[enddate,])
max(SSb[enddate,])
annualRtnb <- (SSb[enddate,])^(1/8)-1  # annual return
min(annualRtnb)
max(annualRtnb)
Eq_annualRtnb <- (mean(SSb[enddate]))^(1/8)-1
Eq_annualRtnb
Eq_AnnualRiskb <- sd(Eq_Drb)*sqrt(250)
Eq_AnnualRiskb
Eq_annualRtnb/Eq_AnnualRiskb

Eq_skewb <- skewness(Eq_Drb)
Eq_skewb
min(skewness(Drb[startdate:enddate,]))
max(skewness(Drb[startdate:enddate,]))

Eq_kurtb <- kurtosis(Eq_Drb)
Eq_kurtb
min(kurtosis(Drb[startdate:enddate,]))
max(kurtosis(Drb[startdate:enddate,]))

Eq_VAR_1d <- -quantile(Eq_Drb,0.05)
Eq_VAR_1d
-quantile(Drb[startdate:enddate,],0.05)

Eq_VAR_1m <- qnorm(0.95)*sd(Eq_Drb)*sqrt(22)-mean(Eq_Drb)
Eq_VAR_1m

# NumPCA[startdate:enddate]  # PLOT!
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


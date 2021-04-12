#!/usr/local/bin//Rscript --vanilla


# options(warn=1)
options(echo=TRUE)

require(colorout)
library(data.table)
library(magrittr)
library(stringr)
library(pbapply)

library(libbib)   # version 1.0 on CRAN

source("../utils/utils.R")



dat <- readRDS("../2-join-them/big-sierra-comb.datatable")

dat[,.N]
# 2021-04-08:	15,715,406


dat[bibid=="20869063"] # :)

keepcols(dat, c("bibid", "itemid", "isbn", "issn"))
gc()

handle_multiple_isbn <- function(astring){
  if(is.na(astring))
    return(NA)
  if(!str_detect(astring, ";"))
    return(normalize_isbn(astring, convert.to.isbn.13=TRUE, aggressive=FALSE))
  these <- str_split(astring, pattern=";")
  these %>% unlist -> these
  normalize_isbn(these, convert.to.isbn.13=TRUE, aggressive=FALSE) -> these
  these[!is.na(these)] -> these
  these[!duplicated(these)] -> these
  return(paste(these, sep=";", collapse=";"))
}



# 13 minutes
  system.time(
dat[, pbsapply(isbn, handle_multiple_isbn, USE.NAMES=FALSE, cl=11)] -> hope
  )

data.table(bibid=dat[, bibid], itemid=dat[,itemid], isbn=dat[,isbn], fixed.isbns.maybe=hope) %>%
  fwrite("./fixed-isbns-maybe3.txt", sep="\t")
rm(hope)
gc()



# --------------------------------------------------------------- #


handle_multiple_issn <- function(astring){
  if(is.na(astring))
    return(NA)
  if(!str_detect(astring, ";"))
    return(normalize_issn(astring,  aggressive=FALSE))
  these <- str_split(astring, pattern=";")
  these %>% unlist -> these
  normalize_issn(these, aggressive=FALSE) -> these
  these[!is.na(these)] -> these
  these[!duplicated(these)] -> these
  return(paste(these, sep=";", collapse=";"))
}

# 2 minutes
  system.time(
dat[, pbsapply(issn, handle_multiple_issn, USE.NAMES=FALSE, cl=11)] -> hope
  )

data.table(bibid=dat[, bibid], itemid=dat[,itemid],  issn=dat[,issn], fixed.issns.maybe=hope) %>%
  fwrite("./fixed-issns-maybe3.txt", sep="\t")


# --------------------------------------------------------------- #





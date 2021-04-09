#!/usr/local/bin//Rscript --vanilla


# ------------------------------ #
rm(list=ls())

options(echo=TRUE)

args <- commandArgs(trailingOnly=TRUE)

require(colorout)
library(data.table)
library(magrittr)
library(stringr)
library(pbapply)

source("../utils/bibcodes.R")
source("../utils/utils.R")
# ------------------------------ #


dat <- readRDS("../2-join-them/big-sierra-comb.datatable")


fisbn <- fread("./fixed-isbns-maybe3.txt", colClasses="character", na.strings=c("", "NA"))
fissn <- fread("./fixed-issns-maybe3.txt", colClasses="character", na.strings=c("", "NA"))


fisbn[, .N]
fissn[, .N]
dat[, .N]
# 2021-03-18:	15,715,406


dat[bibid!=fisbn[, bibid]]
dat[itemid!=fisbn[, itemid]]

dat[bibid!=fissn[, bibid]]
dat[itemid!=fissn[, itemid]]


# next time, ¿should I save the old ones?
fissn[, fixed.issns.maybe] -> tmp
dat[, fisbn:=fisbn[, fixed.isbns.maybe]]
dat[, issn:=tmp]
dat[, isbn:=fisbn]
dat[, fisbn:=NULL]

dat %>% names

dat[bibid=="20869063"] # :)

rm(fisbn)
rm(fissn)
gc()


dat[, lccn:=normalize_lccn(lccn)]

dat[!is.na(lccn) & lccn=="", .(lccn)]
dat[lccn=="", lccn:=NA]

dat[!is.na(lccn), .(lccn)]
dat[lccn=="###00000000#", lccn:=NA]


dat[, .N, !is.na(oclc)]
  ## 2021-04-08
   #  is.na        N
   # <lgcl>    <int>
   # 1:  FALSE  5533432
   # 2:   TRUE 10181974
dat[!is.na(oclc), .(oclc)]


clean_oclc <- function(astrings){
  astrings <- str_replace(astrings, "\\D?[Bb]$", "")
  astrings <- str_replace(astrings, "^OCLC", "")
  astrings[str_detect(astrings, "aa")] <- NA
  astrings[str_detect(astrings, "NYPG")] <- NA
  astrings[str_detect(astrings, "nypg")] <- NA
  astrings <- str_replace(astrings, "^(\\d{5,}) \\(.+$", "\\1")
  astrings[str_detect(astrings, "\\D")] <- NA
  return(astrings)
}


handle_multiple_oclc <- function(astrings){
  if(is.na(astrings))
    return(NA)
  if(!str_detect(astrings, ";"))
    return(clean_oclc(astrings))
  these <- str_split(astrings, pattern=";")
  these %>% unlist -> these
  clean_oclc(these) -> these
  these[!is.na(these)] -> these
  these[!duplicated(these)] -> these
  return(paste(these, sep=";", collapse=";"))
}


gc()

# 15 minutes
  system.time(
dat[, pbsapply(oclc, handle_multiple_oclc, USE.NAMES=FALSE, cl=9)] -> hope
  )

dat[, foclc:=hope]
dat[!is.na(oclc) & str_detect(oclc, ";"), .(oclc)]
dat[!is.na(oclc) & str_detect(oclc, "[Bb]"), .(oclc, foclc)]

dat[, oclc:=foclc]
delcols(dat, "foclc")

rm(hope)
gc()




# NOW ON TO DATES
dat[!is.na(pub_year) & pub_year > 2021, pub_year:=NA]
dat[!is.na(pub_year) & pub_year < 170, pub_year:=NA]
dat[!is.na(pub_year) & pub_year==999, pub_year:=NA]
dat[!is.na(pub_year) & pub_year < 1000 & pub_year > 201, pub_year:=NA]
dat[!is.na(pub_year) & pub_year < 1000, pub_year:=as.integer(10*pub_year)]

#### THIS IS TERRIBLE. GET IT FROM THE 008 FIELD INSTEAD
## or in addition
## or maybe not



dat[, .N]
dat[!is.na(oclc), .N]
dat[!is.na(oclc), .N] / dat[, .N]

# 65% ?!!?!!
# are they all valid?!??!

dat %>% saveRDS("target/big-healed-sierra-comb.datatable")


# dat[itype_dp<100, ] %>% saveRDS("../target/research-joined.datatable")
# dat[itype_dp>100, ] %>% saveRDS("../target/branch-joined.datatable")




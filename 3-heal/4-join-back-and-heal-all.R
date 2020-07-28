#!/usr/bin/Rscript --vanilla

# #!/usr/local/bin//Rscript --vanilla


# ------------------------------ #
rm(list=ls())

options(echo=TRUE)

args <- commandArgs(trailingOnly=TRUE)

library(colorout)
library(data.table)
library(magrittr)
library(stringr)
library(pbapply)

source("./bibcodes.R")
source("./utils.R")
# ------------------------------ #


dat <- readRDS("../2-join-them/big-sierra-comb.datatable")


fisbn <- fread("./fixed-isbns-maybe3.txt", colClasses="character", na.strings=c("", "NA"))
fissn <- fread("./fixed-issns-maybe3.txt", colClasses="character", na.strings=c("", "NA"))


fisbn[, .N]
fissn[, .N]
dat[, .N]

dat[bibid!=fisbn[, bibid]]
dat[itemid!=fisbn[, itemid]]

dat[bibid!=fissn[, bibid]]
dat[itemid!=fissn[, itemid]]

# dat[1:1000,][, .(isbn, fisbn[, fixed.isbns.maybe])]

fissn[, fixed.issns.maybe] -> tmp
dat[, fisbn:=fisbn[, fixed.isbns.maybe]]
dat[, issn:=tmp]
dat[, isbn:=fisbn]
dat[, fisbn:=NULL]

dat %>% names

# delcols(dat, "location")


rm(fisbn)
rm(fissn)
gc()


dat[, lccn:=normalize_lccn(lccn)]

dat[!is.na(lccn) & lccn=="", .(lccn)]
dat[lccn=="", lccn:=NA]

dat[!is.na(lccn), .(lccn)]
dat[lccn=="###00000000#", lccn:=NA]


dat[, .N, !is.na(oclc)]
dat[!is.na(oclc), .(oclc)]

# dat[str_detect(oclc, ";"), .(oclc)][1:30]
# dat[!str_detect(oclc, "NYPG") & str_detect(oclc, "[A-Za-z]"), .(oclc)][1:30]
# dat[!str_detect(oclc, "NYPG") & !str_detect(oclc, "[Bb]$") & str_detect(oclc, "[A-Za-z]"), .(oclc, clean_oclc(oclc))][1:30]
# dat[!str_detect(oclc, "NYPG") & !str_detect(oclc, "[Bb]$") & str_detect(oclc, "[A-Za-z]"), .N]


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

# 16 minutes
  system.time(
dat[, pbsapply(oclc, handle_multiple_oclc, USE.NAMES=FALSE, cl=6)] -> hope
  )

dat[, foclc:=hope]
dat[!is.na(oclc) & str_detect(oclc, ";"), .(oclc)]
dat[!is.na(oclc) & str_detect(oclc, "[Bb]"), .(oclc, foclc)]

dat[, oclc:=foclc]
delcols(dat, "foclc")

rm(hope)
gc()





dat[, .N]
dat[!is.na(oclc), .N]
dat[!is.na(oclc), .N] / dat[, .N]

# 65% ?!!?!!
# are they all valid?!??!

dat %>% saveRDS("target/big-healed-sierra-comb.datatable")


# dat[itype_dp<100, ] %>% saveRDS("../target/research-joined.datatable")
# dat[itype_dp>100, ] %>% saveRDS("../target/branch-joined.datatable")




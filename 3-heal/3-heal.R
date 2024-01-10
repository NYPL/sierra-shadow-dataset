#!/usr/local/bin//Rscript --vanilla


# ------------------------------ #
rm(list=ls())

options(echo=TRUE)
options(width=80)
options(warn=2)
options(scipen=10)
options(datatable.prettyprint.char=50)
options(datatable.print.class=TRUE)
options(datatable.print.keys=TRUE)
options(datatable.fwrite.sep='\t')
options(datatable.na.strings="")

args <- commandArgs(trailingOnly=TRUE)

library(colorout)
library(data.table)
library(magrittr)
library(stringr)
library(libbib)    # >= v1.6.2
library(pbapply)

# ------------------------------ #



# around 3 minutes
dat <- fread_plus_date("../2-join-them/target/big-sierra-comb.dat.gz",
                       strip.white=FALSE,
                       colClasses=c("suppressed"="factor", "source"="factor",
                                    "catalogdate"="character",
                                    "biblevel"="factor", "mattype"="factor",
                                    "langcode"="factor", "lang"="factor",
                                    "countrycode"="factor", "country"="factor",
                                    "nypltype"="factor",
                                    "hasmultbibids"="logical",
                                    "status"="factor",
                                    "item_location_code_dp"="factor",
                                    "item_location_str_dp"="factor"))
expdate <- attr(dat, "lb.date")

dat[bibid==20869063] # :)


# --------------------------------------------------------------- #

##########
####  ISBN
dat[!is.na(isbn),
    isbn:=split_map_filter_reduce(isbn,
                                  mapfun=function(x){
                                    normalize_isbn(x, convert.to.isbn.13=TRUE)
                                  },
                                  filterfun=remove_duplicates_and_nas,
                                  reduxfun=recombine_with_sep_closure(),
                                  cl=3)]
#    39 minutes
# or 24 minutes
# or 13 minutes
# or 58 minutes
# or 31 minutes
# or 1 hour and 18 minutes
# or 1 hour

# --------------------------------------------------------------- #

##########
####  ISSN
dat[!is.na(issn),
    issn:=split_map_filter_reduce(issn,
                                  mapfun=function(x){normalize_issn(x)},
                                  filterfun=remove_duplicates_and_nas,
                                  reduxfun=recombine_with_sep_closure(),
                                  cl=3)]
# 2 minutes

# --------------------------------------------------------------- #

##########
####  LCCN
dat[, lccn:=normalize_lccn(lccn)]

# 2 minutes
# or 14 minutes

# --------------------------------------------------------------- #

##########
####  OCLC

# ugly
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

dat[!is.na(oclc),
    oclc:=split_map_filter_reduce(oclc,
                                  mapfun=function(x){clean_oclc(x)},
                                  filterfun=remove_duplicates_and_nas,
                                  reduxfun=recombine_with_sep_closure(),
                                  cl=3)]
#    30 minutes
# or 18 minutes
# or 26 minutes
# or 18 minutes
# or 26 minutes
# or 1 hour and 5 minutes


# --------------------------------------------------------------- #

###########
####  DATES

# getting the date from the 008 is a dead end


CURRENT_YEAR <- as.integer(str_sub(expdate, 0, 4))
dat[!is.na(pub_year) & pub_year > CURRENT_YEAR, pub_year:=NA]
dat[!is.na(pub_year) & pub_year < 170, pub_year:=NA]
dat[!is.na(pub_year) & pub_year==999, pub_year:=NA]
dat[!is.na(pub_year) & pub_year < 1000 & pub_year > 201, pub_year:=NA]
dat[!is.na(pub_year) & pub_year < 1000, pub_year:=as.integer(10*pub_year)]

# --------------------------------------------------------------- #

# interlude to remove "_dp" from names
setnames(dat, "callnum_dp", "item_callnum")

dat %>% names %>% str_replace("_dp$", "") -> withoutdp
setnames(dat, withoutdp)


# --------------------------------------------------------------- #

#########################
####  BRANCH OR RESEARCH

dat[itype<=100, branch_or_research:="research"]
dat[itype>100, branch_or_research:="branch"]

dat[, is_mixed_bib:=uniqueN(branch_or_research)>1, bibid]

# --------------------------------------------------------------- #

##########################
####  CALL NUMBER SUBJECTS

## BEGIN DEWEY

dat[branch_or_research=="branch",] %>% dt_percent_not_na("callnum2")
# 2021-04: 99.77%
# 2021-09: 99.75%
# 2022-04: 99.78%

dat[, ddc:=str_replace(callnum2, "[^\\d\\.].*$", "")]
dat[!str_detect(ddc, "^\\d"), ddc:=NA]

# some are hanging out in `item_callnum`
dat[is.na(ddc) &
    str_detect(item_callnum, "^\\d{3}") &
    branch_or_research=="branch",
  ddc:=str_replace(item_callnum, "[^\\d\\.].*$", "")]
dat[!str_detect(ddc, "^\\d"), ddc:=NA]


dat[!is.na(ddc), .(ddc)]
dat[branch_or_research=="branch",] %>% dt_percent_not_na("ddc")
# 2021-04: 30% :(
# 2021-09: 32% :(
# 2022-04: 32% :(
# 2022-07: 34%

dat[, dewey_class:=get_dewey_decimal_subject_class(ddc)]
dat[, dewey_division:=get_dewey_decimal_subject_division(ddc)]
dat[, dewey_section:=get_dewey_decimal_subject_section(ddc)]

## END DEWEY



## BEGIN LC

just_valid_lccalls <- function(x){ x[is_valid_lc_call(x)] }

# just 2 minutes
dat[!is.na(lccall) & str_detect(lccall, ";"),
    lccall:=split_map_filter_reduce(lccall, mapfun=just_valid_lccalls,
                                    filterfun=remove_duplicates_and_nas, cl=7)]

dat[, lc_subject_class:=get_lc_call_subject_classification(lccall)]
dat[, lc_subject_subclass:=get_lc_call_subject_classification(lccall,
                                                              subclassification=TRUE)]

dat[branch_or_research=="research"] %>% dt_counts_and_percents("lc_subject_class")
# 57% is NA
dat[branch_or_research=="research"] %>% dt_counts_and_percents("lc_subject_subclass")
# 57% is NA

# --------------------------------------------------------------- #


set_lb_date(dat, expdate)
dat %>% fwrite_plus_date("./target/big-healed-sierra-comb-just-two-years.dat.gz",
                         sep="\t")


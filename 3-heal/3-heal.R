#!/usr/local/bin//Rscript --vanilla


# ------------------------------ #
rm(list=ls())

options(echo=TRUE)
options(width = 80)
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
library(libbib)       # version 1.5.3
library(pbapply)

# ------------------------------ #



system.time(    # REMOVE
dat <- fread("../2-join-them/target/big-sierra-comb.dat.gz",
             strip.white=FALSE)
)

dat[,.N]
# 2021-04-08:	15,715,406


dat[bibid=="20869063"] # :)


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
                                  cl=9)]
# 39 minutes

# --------------------------------------------------------------- #

##########
####  ISSN
dat[!is.na(issn),
    issn:=split_map_filter_reduce(issn,
                                  mapfun=function(x){normalize_issn(x)},
                                  filterfun=remove_duplicates_and_nas,
                                  reduxfun=recombine_with_sep_closure(),
                                  cl=7)]
# 2 minutes

# --------------------------------------------------------------- #

##########
####  LCCN
dat[, lccn:=normalize_lccn(lccn)]
# 2 minutes


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
                                  cl=7)]
# 30 minutes

# --------------------------------------------------------------- #


###########
####  DATES

system.time(
dat[, tmpdate:=marc_008_get_info(oh08)[,pub_date]]
)

dat %>% dt_percent_not_na("pub_year")
dat %>% dt_percent_not_na("tmpdate")

dat[pub_year!=tmpdate, .(bibid, pub_year, tmpdate)]


# --------------------------------------------------------------- #


##########################
####  CALL NUMBER SUBJECTS

## BEGIN DEWEY

dat[, dewey_class:=get_dewey_decimal_subject_class(callnum2)]
## 2021-04
dat[,.N, is.na(dewey_class)]
#     is.na        N
#    <lgcl>    <int>
#    1:   TRUE 14208875
#    2:  FALSE  1,506,531
dat[!is.na(dewey_class)] %>% dt_counts_and_percents("dewey_class")
#                                     dewey_class     val percent
#                                          <char>   <int>   <num>
#  1: Social sciences, sociology and anthropology  316626   21.02
#  2:                                  Technology  272622   18.10
#  3:                                     History  222334   14.76
#  4:                                     Science  184633   12.26
#  5:                                        Arts  175958   11.68
#  6:    Literature (Belles-lettres) and rhetoric  123444    8.19
#  7:                   Philosophy and psychology   65595    4.35
#  8:                                    Language   51004    3.39
#  9:     Computer science, knowledge and systems   50257    3.34
# 10:                                    Religion   44058    2.92
# 11:                                       TOTAL 1506531  100.00

dat[, dewey_division:=get_dewey_decimal_subject_division(callnum2)]

dat[is.na(dewey_division) & !is.na(dewey_class)]
dat[!is.na(dewey_division)] %>% dt_counts_and_percents("dewey_division", .N)

dat[, dewey_section:=get_dewey_decimal_subject_section(callnum2)]

dat[is.na(dewey_section) & !is.na(dewey_class)]
dat[!is.na(dewey_section)] %>% dt_counts_and_percents("dewey_section", .N)

## END DEWEY


## LC

just_valid_lccalls <- function(x){
  x[is_valid_lc_call(x)]
}

dat[!is.na(lccall) & str_detect(lccall, ";"),
    lccall:=split_map_filter_reduce(lccall, mapfun=just_valid_lccalls,
                                    filterfun=remove_duplicates_and_nas, cl=7)]

dat[, lc_subject_class:=get_lc_call_subject_classification(lccall)]

dat[, .(lccall, lc_subject_class)]
dat[!is.na(lccall) & is.na(lc_subject_class), .(lccall, lc_subject_class)]
dat[!is.na(lccall), .N, is.na(lc_subject_class)]
dat[!is.na(lccall), .N, is.na(lc_subject_class)]
#     is.na       N
#    <lgcl>   <int>
# 1:  FALSE 8295402
# 2:   TRUE  319719

dat[, lccall:=str_replace(str_replace(lccall, "]", ""), "\\[", "")]
dat[, lc_subject_class:=get_lc_call_subject_classification(lccall)]
dat[!is.na(lccall), .N, is.na(lc_subject_class)]
#     is.na       N
#    <lgcl>   <int>
# 1:  FALSE 8296239
# 2:   TRUE  318882



dat[, lc_subject_class:=get_lc_call_subject_classification(lccall)]
dat[!is.na(lccall), .N, is.na(lc_subject_class)]
#  is.na       N
# <lgcl>   <int>
# 1:  FALSE 8306750
# 2:   TRUE  307931

dat %>% dt_counts_and_percents("lc_subject_class")





# --------------------------------------------------------------- #


#########################
####  BRANCH OR RESEARCH

dat[itype<=100, branch_or_research:="research"]
dat[itype>100, branch_or_research:="branch"]

dat[, paste(unique(branch_or_research), sep=";", collapse=";"), bibid] -> tmp

tmp[, is_mixed_bib:=str_detect(V1, ";")]
dt_del_cols(tmp, "V1")

setkey(dat, "bibid")
dat %>% merge(tmp, all.x=TRUE) -> dat





### @@@ clean _dp names

### @@@ !!!! CHANGE README (also for step2)




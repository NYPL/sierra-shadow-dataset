#!/usr/local/bin//Rscript --vanilla


# ------------------------------ #
rm(list=ls())

options(echo=TRUE)

args <- commandArgs(trailingOnly=TRUE)

require(colorout)
library(data.table)
library(magrittr)
library(stringr)

library(libbib)         # version 1.3

# ------------------------------ #


dat <- readRDS("../3-heal/target/big-healed-sierra-comb.datatable")

old <- readRDS("./historical-circ.datatable")

dat %>% names

# common lisp companion
old[bibid=="11463118", ]
dat[bibid=="11463118", .(title, total_checkouts_dp, total_renewals_dp, last_year_circ_dp, this_year_circ_dp)]

# knot book comparison
old[bibid=="11315077"]
dat[bibid=="11315077"]
dat[itemid=="14021710"]
dat[bibid=="11315077", .(title, total_checkouts_dp, total_renewals_dp, last_year_circ_dp, this_year_circ_dp)]

# de sueños azules y contrasueños
old[bibid=="12453190"]
dat[bibid=="12453190", .(title, total_checkouts_dp, total_renewals_dp, last_year_circ_dp, this_year_circ_dp)]

# SICP
dat[bibid=="11366725", .(title, total_checkouts_dp, total_renewals_dp, last_year_circ_dp, this_year_circ_dp)]

# probable and provable
old[bibid=="11061659"]
dat[bibid=="11061659", .(title, total_checkouts_dp, total_renewals_dp, last_year_circ_dp, this_year_circ_dp)]

# art and culture (clement greenberg)
old[bibid=="13967181"]
dat[bibid=="13967181", .(title, total_checkouts_dp, total_renewals_dp, last_year_circ_dp, this_year_circ_dp)]

# :)
old[bibid=="20869063"]
dat[bibid=="20869063", .(title, total_checkouts_dp, total_renewals_dp, last_year_circ_dp, this_year_circ_dp)]



#### UPDATE EVERY YEAR!!! ####
#### UPDATE EVERY YEAR!!! ####
#### UPDATE EVERY YEAR!!! ####
setnames(dat, "last_year_circ_dp", "fy20_checkouts")
setnames(dat, "this_year_circ_dp", "fy21_checkouts")
setnames(dat, "total_circ_dp", "total_circ")

setkey(old, "bibid", "itemid")
setkey(dat, "bibid", "itemid")

  system.time(    # less than a minute
dat %>% merge(old, all.x=TRUE) -> comb
  )

rm(dat)
rm(old)
gc()


comb[bibid=="11463118"] # common lisp companion
comb[bibid=="11366725"] # SICP
comb[bibid=="11061659"] # probable and provable
comb[bibid=="12453190"] # de sueños azules y contrasueños
comb[bibid=="20869063"] # :)





# renaming and things

setnames(comb, "callnum_dp", "item_callnum")
comb %>% names %>% str_replace("_dp$", "") -> thenewnames
setnames(comb, thenewnames)
comb %>% names

comb[itype<=100, branch_or_research:="research"]
comb[itype>100, branch_or_research:="branch"]

comb[, paste(unique(branch_or_research), sep=";", collapse=";"), bibid] -> tmp

tmp[, is_mixed_bib:=str_detect(V1, ";")]
dt_del_cols(tmp, "V1")

setkey(comb, "bibid")
comb %>% merge(tmp, all.x=TRUE) -> comb

comb %>% names

setcolorder(comb, c("bibid", "itemid", "inbibtable", "initemtable",
                    "suppressed", "itype", "branch_or_research",
                    "is_mixed_bib"))
comb %>% names
comb %>% names %>% length
#### MAYBE CHANGE EVERY TIME ####
#### MAYBE CHANGE EVERY TIME ####
#### MAYBE CHANGE EVERY TIME ####
setcolorder(comb, c(names(comb)[1:52],
                    "created_date",
                    "total_checkouts",
                    "total_renewals",
                    "total_circ",
                    "fy17_checkouts",
                    "fy18_checkouts",
                    "fy19_checkouts",
                    "fy20_checkouts",
                    "fy21_checkouts"))
comb %>% names %>% length

setkey(comb, "bibid")


#### CHANGE EVERY YEAR ####
#### CHANGE EVERY YEAR ####
#### CHANGE EVERY YEAR ####
  system.time(    # less than one minute
comb[, .(bib_fy17_checkouts         = sum(fy17_checkouts, na.rm=TRUE),
         bib_fy18_checkouts         = sum(fy18_checkouts, na.rm=TRUE),
         bib_fy19_checkouts         = sum(fy19_checkouts, na.rm=TRUE),
         bib_fy20_checkouts         = sum(fy20_checkouts, na.rm=TRUE),
         bib_fy21_checkouts         = sum(fy21_checkouts, na.rm=TRUE),
         bib_total_checkouts        = sum(total_checkouts, na.rm=TRUE),
         bib_total_renewals         = sum(total_renewals, na.rm=TRUE),
         bib_total_circ             = sum(total_circ, na.rm=TRUE)),
      bibid] -> agg
  )

setkey(agg, "bibid")
setkey(comb, "bibid")

comb %>% merge(agg, all.x=TRUE) -> big

rm(comb)
rm(agg)
gc()


#### SUBJECT

## dewey

big[, dewey_class:=get_dewey_decimal_subject_class(callnum2)]
## 2021-04
big[,.N, is.na(dewey_class)]
#     is.na        N
#    <lgcl>    <int>
#    1:   TRUE 14208875
#    2:  FALSE  1,506,531
big[!is.na(dewey_class)] %>% dt_counts_and_percents("dewey_class")
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

big[, dewey_division:=get_dewey_decimal_subject_division(callnum2)]

big[is.na(dewey_division) & !is.na(dewey_class)]
big[!is.na(dewey_division)] %>% dt_counts_and_percents("dewey_division", .N)

big[, dewey_section:=get_dewey_decimal_subject_section(callnum2)]

big[is.na(dewey_section) & !is.na(dewey_class)]
big[!is.na(dewey_section)] %>% dt_counts_and_percents("dewey_section", .N)

## end dewey

## LC

big[, lc_subject_class:=get_lc_call_subject_classification(lccall)]

big[, .(lccall, lc_subject_class)]
big[!is.na(lccall) & is.na(lc_subject_class), .(lccall, lc_subject_class)]
big[!is.na(lccall), .N, is.na(lc_subject_class)]
big[!is.na(lccall), .N, is.na(lc_subject_class)]
#     is.na       N
#    <lgcl>   <int>
# 1:  FALSE 8295402
# 2:   TRUE  319719

big[, lccall:=str_replace(str_replace(lccall, "]", ""), "\\[", "")]
big[, lc_subject_class:=get_lc_call_subject_classification(lccall)]
big[!is.na(lccall), .N, is.na(lc_subject_class)]
#     is.na       N
#    <lgcl>   <int>
# 1:  FALSE 8296239
# 2:   TRUE  318882



just_valid_lccalls <- function(x){
  x[is_valid_lc_call(x)]
}

# experiment
big[!is.na(lccall) & str_detect(lccall, ";"),
    lccall:=split_map_filter_reduce(lccall, mapfun=just_valid_lccalls,
                                    filterfun=remove_duplicates_and_nas, cl=7)]
big[, lc_subject_class:=get_lc_call_subject_classification(lccall)]
big[!is.na(lccall), .N, is.na(lc_subject_class)]
#  is.na       N
# <lgcl>   <int>
# 1:  FALSE 8306750
# 2:   TRUE  307931

big %>% dt_counts_and_percents("lc_subject_class")



big[str_detect(lccall, ";"), .(lccall)]


#### END SUBJECT



big[branch_or_research=="branch"] -> branch
branch %>% saveRDS("../target/sierra-branch-healed-joined.datatable")


big %>% saveRDS("../target/sierra-all-healed-joined.datatable")



research <- big[branch_or_research=="research"]
rm(big)
rm(branch)
gc()


research[, .N]
# 2020-07-23: 10,895,556
# 2021-04-08: 10,888,765



setkey(research, "bibid")

research[, .(research_items_under_bib=.N), bibid] -> agg
setkey(agg, "bibid")
research %>% merge(agg, all.x=TRUE) -> research



#### CHANGE EVERY YEAR ####
#### CHANGE EVERY YEAR ####
#### CHANGE EVERY YEAR ####
  system.time(    # under 2 seconds
research[, .(bib_fy17_checkouts           = sum(fy17_checkouts, na.rm=TRUE),
             bib_fy18_checkouts           = sum(fy18_checkouts, na.rm=TRUE),
             bib_fy19_checkouts           = sum(fy19_checkouts, na.rm=TRUE),
             bib_fy20_checkouts           = sum(fy20_checkouts, na.rm=TRUE),
             bib_fy21_checkouts           = sum(fy21_checkouts, na.rm=TRUE),
             bib_total_checkouts          = sum(total_checkouts, na.rm=TRUE),
             bib_total_renewals           = sum(total_renewals, na.rm=TRUE),
             bib_total_circ               = sum(total_circ, na.rm=TRUE)),
      bibid] -> agg
  )

setkey(agg, "bibid")
setkey(research, "bibid")


intersect(names(agg), names(research)) -> tmp
tmp[tmp!="bibid"] -> tmp
delcols(research, tmp)


research %>% merge(agg, all.x=TRUE) -> big


research[bibid=="12453190", ]


## ADDING LC SUBJECT CLASSIFICATIONS!

research[, lc_suject_classification:=get_lc_call_subject_classification(lccall)]

research[, lc_suject_subclassification:=get_lc_call_subject_classification(lccall,
                                                                           subclassification=TRUE)]

research[!is.na(lccall), .(lccall, lc_suject_classification, lc_suject_subclassification)]

research %>% pivot("lc_suject_classification", .N)



big %>% saveRDS("../target/sierra-research-healed-joined.datatable")



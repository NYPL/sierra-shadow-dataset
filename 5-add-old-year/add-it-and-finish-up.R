#!/usr/local/bin//Rscript --vanilla


# ------------------------------ #
rm(list=ls())

options(echo=TRUE)

args <- commandArgs(trailingOnly=TRUE)

require(colorout)
library(data.table)
library(magrittr)
library(stringr)

source("../utils/utils.R")
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

  # philosophical theology of jonathong edwards
  # the life and theology of the founder of middle knowledge (loiuous molina)
  # [isbn:9780310516972]
# introduction to the phil. of inductuion and probability



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

comb[itype<100, branch_or_research:="research"]
comb[itype>100, branch_or_research:="branch"]

comb[, paste(unique(branch_or_research), sep=";", collapse=";"), bibid] -> tmp

tmp[, is_mixed_bib:=str_detect(V1, ";")]
delcols(tmp, "V1")

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

big[branch_or_research=="branch"] %>% saveRDS("../target/sierra-branch-healed-joined.datatable")
big %>% saveRDS("../target/sierra-all-healed-joined.datatable")


research <- big[branch_or_research=="research"]
rm(big)
gc()


research[, .N]
# 2020-07-23: 10,895,556
# 2021-03-18: 10,878,416 (before fixing!!!)



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


big[bibid=="12453190", ]
big %>% saveRDS("../target/sierra-research-healed-joined.datatable")

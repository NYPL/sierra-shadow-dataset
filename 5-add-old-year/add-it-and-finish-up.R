#!/usr/local/bin//Rscript --vanilla


# ------------------------------ #
rm(list=ls())

options(echo=TRUE)

args <- commandArgs(trailingOnly=TRUE)

library(colorout)
library(data.table)
library(magrittr)
library(stringr)

source("./utils.R")
# ------------------------------ #


dat <- readRDS("../3-heal/target/big-healed-sierra-comb.datatable")

old <- readRDS("./fy17-and-18-circ.datatable")

dat %>% names

# common lisp companion
dat[bibid=="11463118", .(title, total_checkouts_dp, total_renewals_dp, last_year_circ_dp, this_year_circ_dp)]
dat[bibid=="11366725", .(title, total_checkouts_dp, total_renewals_dp, last_year_circ_dp, this_year_circ_dp)]
old[bibid=="11463118", ]
dat[bibid=="11061659", .(title, total_checkouts_dp, total_renewals_dp, last_year_circ_dp, this_year_circ_dp)]


setnames(dat, "last_year_circ_dp", "fy19_checkouts")
setnames(dat, "this_year_circ_dp", "fy20_checkouts")
setnames(dat, "total_circ_dp", "total_circ")

setkey(old, "bibid", "itemid")
setkey(dat, "bibid", "itemid")

system.time(    # less than a minute
dat %>% merge(old, all.x=TRUE) -> comb
)

rm(dat)
rm(old)
gc()


comb[bibid=="11463118"]
comb[bibid=="11366725"]
comb[bibid=="11463118"]
comb[bibid=="11061659"]



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

setcolorder(comb, c(names(comb)[1:52],
                    "created_date",
                    "total_checkouts",
                    "total_renewals",
                    "total_circ",
                    "fy17_checkouts",
                    "fy18_checkouts",
                    "fy19_checkouts",
                    "fy20_checkouts"))

setkey(comb, "bibid")


  system.time(    # less than one minute
comb[, .(bib_fy17_checkouts         = sum(fy17_checkouts, na.rm=TRUE),
         bib_fy18_checkouts         = sum(fy18_checkouts, na.rm=TRUE), #!!!!
         bib_fy19_checkouts         = sum(fy19_checkouts, na.rm=TRUE),
         bib_fy20_checkouts         = sum(fy20_checkouts, na.rm=TRUE),
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


# 2020-07-23: 10,895,556
research[, .N]


setkey(research, "bibid")

research[, .(research_items_under_bib=.N), bibid] -> agg
setkey(agg, "bibid")
research %>% merge(agg, all.x=TRUE) -> research



  system.time(    # under 2 seconds
research[, .(bib_fy17_checkouts           = sum(fy17_checkouts, na.rm=TRUE),
             bib_fy18_checkouts           = sum(fy18_checkouts, na.rm=TRUE),
             bib_fy19_checkouts           = sum(fy19_checkouts, na.rm=TRUE),
             bib_fy20_checkouts           = sum(fy20_checkouts, na.rm=TRUE),
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

big %>% saveRDS("../target/sierra-research-healed-joined.datatable")

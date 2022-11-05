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
library(libbib)     # >= v1.6.2

# ------------------------------ #


dat <- fread_plus_date("../3-heal/target/big-healed-sierra-comb-just-two-years.dat.gz",
                       strip.white=FALSE,
                       colClasses=c("suppressed"="factor", "source"="factor",
                                    "biblevel"="factor", "mattype"="factor",
                                    "langcode"="factor", "lang"="factor",
                                    "countrycode"="factor", "country"="factor",
                                    "nypltype"="factor", "hasmultbibids"="logical",
                                    "status"="factor",
                                    "item_location_code"="factor",
                                    "item_location_str"="factor"))
expdate <- attr(dat, "lb.date")

# ensures that years aren't messed up
if(as.Date(expdate) > as.Date("2023-06-30"))
  stop("new year. make sure you update this script")

old <- fread("../data/historical-circ/historical-circ-fy17-fy21.dat.gz")

dat %>% names

# common lisp companion
old[bibid=="11463118", ]
dat[bibid=="11463118", .(title, total_checkouts, total_renewals, last_year_circ, this_year_circ)]

# knot book comparison
old[bibid=="11315077"]
dat[bibid=="11315077"]
dat[itemid=="14021710"]
dat[bibid=="11315077", .(title, total_checkouts, total_renewals, last_year_circ, this_year_circ)]

# de sueños azules y contrasueños
old[bibid=="12453190"]
dat[bibid=="12453190", .(title, total_checkouts, total_renewals, last_year_circ, this_year_circ)]

# SICP
old[bibid=="11366725"]
dat[bibid=="11366725", .(title, total_checkouts, total_renewals, last_year_circ, this_year_circ)]

# probable and provable
old[bibid=="11061659"]
dat[bibid=="11061659", .(title, total_checkouts, total_renewals, last_year_circ, this_year_circ)]

# art and culture (clement greenberg)
old[bibid=="13967181"]
dat[bibid=="13967181", .(title, total_checkouts, total_renewals, last_year_circ, this_year_circ)]

# :)
old[bibid=="20869063"]
dat[bibid=="20869063", .(title, total_checkouts, total_renewals, last_year_circ, this_year_circ)]



#### UPDATE EVERY YEAR!!! ####
#### UPDATE EVERY YEAR!!! ####
#### UPDATE EVERY YEAR!!! ####
setnames(dat, "last_year_circ", "fy21_checkoutsp")
setnames(dat, "this_year_circ", "fy22_checkouts")

setkey(old, "bibid", "itemid")
setkey(dat, "bibid", "itemid")

dat %>% merge(old, all.x=TRUE) -> comb

comb %>% names

# comb[!is.na(fy21_checkouts) & !is.na(fy21_checkoutsp),
#      .(fy21_checkouts, fy21_checkoutsp)]
#
# comb[!is.na(fy21_checkouts) & !is.na(fy21_checkoutsp) &
#      fy21_checkoutsp > fy21_checkouts,
#      .(fy21_checkouts, fy21_checkoutsp)][,.N]
#
# comb[!is.na(fy21_checkouts) & !is.na(fy21_checkoutsp) &
#      fy21_checkoutsp < fy21_checkouts,
#      .(fy21_checkouts, fy21_checkoutsp)][,.N]
#
# comb[!is.na(fy22_checkouts) & !is.na(fy21_checkoutsp) &
#      fy21_checkoutsp < fy21_checkouts,
#      .(fy21_checkouts, fy21_checkoutsp)][,.N]
#
# comb[, fy21_checkoutsp:=NULL]


rm(dat)
rm(old)
gc()

comb[bibid=="11463118"] # common lisp companion
comb[bibid=="11366725"] # SICP
comb[bibid=="11061659"] # probable and provable
comb[bibid=="12453190"] # de sueños azules y contrasueños
comb[bibid=="20869063"] # :)


setcolorder(comb, c("bibid", "itemid", "inbibtable", "initemtable",
                    "suppressed", "itype", "branch_or_research",
                    "is_mixed_bib"))
comb %>% names
#### CHANGE EVERY YEAR ####
#### CHANGE EVERY YEAR ####
#### CHANGE EVERY YEAR ####
comb %>% names %>% length     # 68

setkey(comb, "bibid")


#### CHANGE EVERY YEAR ####
#### CHANGE EVERY YEAR ####
#### CHANGE EVERY YEAR ####
comb[, .(bib_fy17_checkouts         = sum(fy17_checkouts, na.rm=TRUE),
         bib_fy18_checkouts         = sum(fy18_checkouts, na.rm=TRUE),
         bib_fy19_checkouts         = sum(fy19_checkouts, na.rm=TRUE),
         bib_fy20_checkouts         = sum(fy20_checkouts, na.rm=TRUE),
         bib_fy21_checkouts         = sum(fy21_checkouts, na.rm=TRUE),
         bib_fy22_checkouts         = sum(fy22_checkouts, na.rm=TRUE),
         bib_total_checkouts        = sum(total_checkouts, na.rm=TRUE),
         bib_total_renewals         = sum(total_renewals, na.rm=TRUE),
         bib_total_circ             = sum(total_circ, na.rm=TRUE)),
      bibid] -> agg

setkey(agg, "bibid")
setkey(comb, "bibid")

comb %>% merge(agg, all.x=TRUE) -> big

rm(comb)
rm(agg)
gc()



# --------------------------------------------------------------- #

##### FINAL NAMES
#### CHANGE EVERY YEAR ####
#### CHANGE EVERY YEAR ####
#### CHANGE EVERY YEAR ####
big %>% names
finalorder <- c("bibid", "itemid", "inbibtable", "initemtable", "suppressed",
                "itype", "branch_or_research", "is_mixed_bib", "leader",
                "oh08", "source", "pub_year", "catalogdate", "bib_location",
                "biblevel", "mattype", "standard_nums", "isbn", "issn", "lccn",
                "oclc", "other_standard", "callnum", "lccall", "callnum2",
                "ddc", "v852a", "langcode", "lang", "countrycode", "country",
                "publisher", "nypltype", "description1", "otherdetails",
                "dimensions", "description2", "description3", "norm_author",
                "norm_title", "author", "title", "num_copies_from_bib",
                "topical_terms", "gen_subdiv_term", "form_subdiv_term",
                "index_term", "geo_terms", "hasmultbibids",
                "item_location_code", "item_location_str", "barcode",
                "item_callnum", "created_date", "status", "total_checkouts",
                "total_renewals", "total_circ", "fy17_checkouts",
                "fy18_checkouts", "fy19_checkouts", "fy20_checkouts",
                "fy21_checkouts", "fy22_checkouts", "bib_fy17_checkouts",
                "bib_fy18_checkouts", "bib_fy19_checkouts",
                "bib_fy20_checkouts", "bib_fy21_checkouts",
                "bib_fy22_checkouts", "bib_total_checkouts",
                "bib_total_renewals", "bib_total_circ", "dewey_class",
                "dewey_division", "dewey_section", "lc_subject_class",
                "lc_subject_subclass")
setcolorder(big, finalorder)

# --------------------------------------------------------------- #




big[branch_or_research=="branch"] -> branch
set_lb_date(branch, expdate)
branch %>% fwrite_plus_date("../target/sierra-branch-healed-joined.dat.gz")

set_lb_date(big, expdate)
big %>% fwrite_plus_date("../target/sierra-all-healed-joined.dat.gz")



research <- big[branch_or_research=="research"]
rm(big)
rm(branch)
gc()


research[, .N]
# 2021-09-09: 10,972,191
# 2021-07-11: 10,945,918
# 2021-04-08: 10,888,765
# 2020-07-23: 10,895,556
# 2022-04-30: 11,079,697
# 2022-07-20: 11,111,941



setkey(research, "bibid")

research[, .(research_items_under_bib=.N), bibid] -> agg
setkey(agg, "bibid")
research %>% merge(agg, all.x=TRUE) -> research



#### CHANGE EVERY YEAR ####
#### CHANGE EVERY YEAR ####
#### CHANGE EVERY YEAR ####
research[, .(bib_fy17_checkouts           = sum(fy17_checkouts, na.rm=TRUE),
             bib_fy18_checkouts           = sum(fy18_checkouts, na.rm=TRUE),
             bib_fy19_checkouts           = sum(fy19_checkouts, na.rm=TRUE),
             bib_fy20_checkouts           = sum(fy20_checkouts, na.rm=TRUE),
             bib_fy21_checkouts           = sum(fy21_checkouts, na.rm=TRUE),
             bib_fy22_checkouts           = sum(fy22_checkouts, na.rm=TRUE),
             bib_total_checkouts          = sum(total_checkouts, na.rm=TRUE),
             bib_total_renewals           = sum(total_renewals, na.rm=TRUE),
             bib_total_circ               = sum(total_circ, na.rm=TRUE)),
      bibid] -> agg

setkey(agg, "bibid")
setkey(research, "bibid")


intersect(names(agg), names(research)) -> tmp
tmp[tmp!="bibid"] -> tmp
dt_del_cols(research, tmp)

research %>% merge(agg, all.x=TRUE) -> research

research[bibid=="12453190", ]


set_lb_date(research, expdate)
research %>% fwrite_plus_date("../target/sierra-research-healed-joined.dat.gz")



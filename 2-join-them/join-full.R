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
library(libbib)   # >= v1.6.2
library(assertr)

# ------------------------------ #



# on a machine with data.table using 10 threads (4.6 GHz)
#   and 64 GB RAM available)

# 4.4 minutes
  system.time(
bibs <- fread_plus_date("../1-export-from-python/bibs/exported-bibs-raw-from-python.dat.gz",
                        quote="", strip.white=FALSE,
                        na.strings=c("NA", "", "NANA"), header=TRUE, sep="\t",
                        colClasses=c("suppressed"="factor", "source"="factor",
                                     "biblevel"="factor", "mattype"="factor",
                                     "langcode"="factor", "lang"="factor",
                                     "countrycode"="factor", "country"="factor",
                                     "nypltype"="factor"))
  )
# 15.6GB 4.3 minutes (without factor specifications)
# 15.1GB 4.1 minutes (with specifications)
expdate <- attr(bibs, "lb.date")


# 1 minute
  system.time(
items <- fread_plus_date("../1-export-from-python/items/exported-items-raw-from-python.dat.gz",
                         na.strings=c("NA", "", "NANA"), header=TRUE, sep="\t",
                         strip.white=FALSE,
                         colClasses=c("itemid"="character",
                                      "hasmultbibids"="logical",
                                      "status"="factor",
                                      "item_location_code_dp"="factor",
                                      "item_location_str_dp"="factor"))
  )

# using 29 GB of RAM now

bibs[, .N]
# bibs %>% verify(nrow(.) >= 15364558, success_fun=success_report) # 2019-10
# bibs %>% verify(nrow(.) >= 15525387, success_fun=success_report) # 2019-12
# bibs %>% verify(nrow(.) >= 15770812, success_fun=success_report) # 2020-07
# bibs %>% verify(nrow(.) >= 15996119, success_fun=success_report) # 2021-04-08
bibs %>% verify(nrow(.) >= 16109207, success_fun=success_report) # 2021-07-11

items[, .N]
# items %>% verify(nrow(.) >= 24349304, success_fun=success_report) # 2019-10
# items %>% verify(nrow(.) >= 24393263, success_fun=success_report) # 2019-12
# items %>% verify(nrow(.) >= 24534875, success_fun=success_report) # 2020-07
# items %>% verify(nrow(.) >= 24033693, success_fun=success_report) # 2021-04-08 # !!!
items %>% verify(nrow(.) >= 24252847, success_fun=success_report) # 2021-07-11


bibs[, bibid:=str_replace_all(bibid, '"', "")]


bibs <- bibs[source=="sierra-nypl"]


setnames(items, "bibid_dp", "bibid")
setkey(items, "bibid")

setkey(bibs, "bibid")
bibs[, inbibtable:=TRUE]


# I guess I have to remove the records with
# invalid bibids from the items table
items <- items[str_detect(bibid, "^\\d+$"), ]
# items[, bibid:=as.integer(bibid)]
items[, initemtable:=TRUE]


# about 2 minutes
  system.time(
bibs %>% merge(items, all=TRUE) -> comb
  )

rm(bibs)
gc()
rm(items)
gc()


comb <- comb[!str_detect(item_location_str_dp, "[pc]ul")]
setcolorder(comb, c("bibid", "itemid", "inbibtable", "initemtable"))

comb %>% names

comb[bibid=="20869063"]     # :)

## debugging
# this was a book about knots that
# I took out 2020-12
comb[bibid=="11315077"]
comb[itemid=="14021710"]


comb <- comb[inbibtable==TRUE]
# wait, ¿then why did I do a full join?

comb <- comb[!is.na(itype_dp),]

# using 49 GBs of memory (old)
# using 35 GBs of memory

comb[, .N]
# comb %>% verify(nrow(.) >= 16243897, success_fun=success_report) # 2020-07
# comb %>% verify(nrow(.) >= 15715406, success_fun=success_report) # 2021-04-08
comb %>% verify(nrow(.) >= 15895579, success_fun=success_report) # 2021-07-11



set_lb_date(comb, expdate)
comb %>% fwrite_plus_date("./target/big-sierra-comb.dat.gz")


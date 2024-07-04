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

# 12 minutes / 6 minutes
  system.time(
bibs <- fread_plus_date("../1-export-from-python/bibs/exported-bibs-raw-from-python.dat.gz",
                        quote="", strip.white=FALSE,
                        na.strings=c("NA", "", "NANA"), header=TRUE, sep="\t",
                        colClasses=c("suppressed"="factor", "source"="factor",
                                     "catalogdate"="character",
                                     "biblevel"="factor", "mattype"="factor",
                                     "langcode"="factor", "lang"="factor",
                                     "countrycode"="factor", "country"="factor",
                                     "nypltype"="factor"))
  )
expdate <- attr(bibs, "lb.date")


# 6 minutes / less than 2 (?)
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

# using 32 GB of RAM now


bibs[, .N]
# bibs %>% verify(nrow(.) >= 15364558, success_fun=success_report) # 2019-10
# bibs %>% verify(nrow(.) >= 15525387, success_fun=success_report) # 2019-12
# bibs %>% verify(nrow(.) >= 15770812, success_fun=success_report) # 2020-07
# bibs %>% verify(nrow(.) >= 15996119, success_fun=success_report) # 2021-04-08
# bibs %>% verify(nrow(.) >= 16109207, success_fun=success_report) # 2021-07-11
# bibs %>% verify(nrow(.) >= 19524093, success_fun=success_report) # 2021-09-09
# bibs %>% verify(nrow(.) >= 19619753, success_fun=success_report) # 2021-10-28
# bibs %>% verify(nrow(.) >= 19812250, success_fun=success_report) # 2022-04-30
# bibs %>% verify(nrow(.) >= 19886220, success_fun=success_report) # 2022-07-20
# bibs %>% verify(nrow(.) >= 20031229, success_fun=success_report) # 2022-10-28
# bibs %>% verify(nrow(.) >= 20243751, success_fun=success_report) # 2023-04-03
# bibs %>% verify(nrow(.) >= 20331796, success_fun=success_report) # 2023-07-10
# bibs %>% verify(nrow(.) >= 21328118, success_fun=success_report) # 2024-01-08
bibs %>% verify(nrow(.) >= 22529303, success_fun=success_report) # 2024-07-01




items[, .N]
# items %>% verify(nrow(.) >= 24349304, success_fun=success_report) # 2019-10
# items %>% verify(nrow(.) >= 24393263, success_fun=success_report) # 2019-12
# items %>% verify(nrow(.) >= 24534875, success_fun=success_report) # 2020-07
# items %>% verify(nrow(.) >= 24033693, success_fun=success_report) # 2021-04-08 # !!!
# items %>% verify(nrow(.) >= 24252847, success_fun=success_report) # 2021-07-11
# items %>% verify(nrow(.) >= 27303800, success_fun=success_report) # 2021-09-09
# items %>% verify(nrow(.) >= 27407393, success_fun=success_report) # 2021-10-28
# items %>% verify(nrow(.) >= 27952208, success_fun=success_report) # 2022-04-30
# items %>% verify(nrow(.) >= 27735720, success_fun=success_report) # 2022-07-20 # !!!
# items %>% verify(nrow(.) >= 27950337, success_fun=success_report) # 2022-10-28
# items %>% verify(nrow(.) >= 28178231, success_fun=success_report) # 2023-04-03
# items %>% verify(nrow(.) >= 28438103, success_fun=success_report) # 2023-07-10
# items %>% verify(nrow(.) >= 29988322, success_fun=success_report) # 2024-01-08
items %>% verify(nrow(.) >= 31526853, success_fun=success_report) # 2024-07-01


bibs[, bibid:=str_replace_all(bibid, '"', "")]


# bibs %>% dt_counts_and_percents("source")
bibs <- bibs[source=="sierra-nypl"]
gc()


setnames(items, "bibid_dp", "bibid")
setkey(items, "bibid")

setkey(bibs, "bibid")
bibs[, inbibtable:=TRUE]


# I guess I have to remove the records with
# invalid bibids from the items table
items <- items[str_detect(bibid, "^\\d+$"), ]
# items[, bibid:=as.integer(bibid)]
items[, initemtable:=TRUE]


# about 3.5 minutes
  system.time(
bibs %>% merge.data.table(items, all=TRUE) -> comb
  )

rm(bibs)
rm(items)
gc()


# this was a bad mistake
# I'm leaving it here so that IT NEVER HAPPENS AGAIN
# comb <- comb[!str_detect(item_location_str_dp, "[pc]ul")]

# 2022-10-28: this is the first time harvard is in the mix
comb <- comb[!(str_detect(item_location_str_dp,
                          "OFFSITE . Request In Advance . (pul|cul|hl)") |
               str_detect(item_location_str_dp,
                          "OFFSITE . ReCAP Partner"))]


setcolorder(comb, c("bibid", "itemid", "inbibtable", "initemtable"))

comb %>% names

comb[bibid=="20869063"]     # :)

## debugging
# this was a book about knots that
# I took out 2020-12
comb[bibid=="11315077"]
comb[itemid=="14021710"]

# book about arduino that I took out
# late March 2023
comb[bibid=="19375763"]


comb <- comb[inbibtable==TRUE]
# wait, ¿then why did I do a full join?

comb <- comb[!is.na(itype_dp),]

# using 49 GBs of memory (old)
# using 35 GBs of memory (old)
# using 42 GBs of memory (old)
# using 44 GBs of memory (old)
# using 48 GBs of memory (old)
# using 51 GBs of memory

comb[, .N]
# comb %>% verify(nrow(.) >= 16243897, success_fun=success_report) # 2020-07
# comb %>% verify(nrow(.) >= 15715406, success_fun=success_report) # 2021-04-08
# comb %>% verify(nrow(.) >= 16122847, success_fun=success_report) # 2021-07-11
# comb %>% verify(nrow(.) >= 15425546, success_fun=success_report) # 2021-09-09
# comb %>% verify(nrow(.) >= 15495704, success_fun=success_report) # 2021-10-28
# comb %>% verify(nrow(.) >= 15853613, success_fun=success_report) # 2022-04-30
# comb %>% verify(nrow(.) >= 15586010, success_fun=success_report) # 2022-07-20 # !!!
# comb %>% verify(nrow(.) >= 15653986, success_fun=success_report) # 2022-10-28 # !!!
# comb %>% verify(nrow(.) >= 15755737, success_fun=success_report) # 2023-04-03
# comb %>% verify(nrow(.) >= 15934042, success_fun=success_report) # 2023-07-10
# comb %>% verify(nrow(.) >= 16097191, success_fun=success_report) # 2024-01-08
comb %>% verify(nrow(.) >= 16330413, success_fun=success_report) # 2024-07-01


set_lb_date(comb, expdate)
comb %>% fwrite_plus_date("./target/big-sierra-comb.dat.gz", sep="\t")


#!/usr/local/bin/Rscript --vanilla

options(echo=TRUE)

require(colorout)
library(data.table)
library(stringr)
library(magrittr)


# on a machine with data.table using 10 threads (4.6 GHz)
#   and 64 GB RAM available)

# 3.5 minutes
  system.time(
bibs <- fread("../1-export-from-python/bibs/exported-bibs-raw-from-python.txt",
              quote="",
              na.strings=c("NA", "", "NANA"), header=TRUE, sep="\t")
  )

# 1 minute
  system.time(
items <- fread("../1-export-from-python/items/exported-items-raw-from-python.txt",
               na.strings=c("NA", "", "NANA"), header=TRUE, sep="\t",
               colClasses=c("itemid"="character"))
  )

# using 29 GB of RAM now

bibs[, .N]
# 15,996,119 (2021-04)
# 15,770,812 (2020-07)
# 15,525,387 (2019-12)
# 15,364,558 (2019-10)
items[, .N]
# 24,033,693 (2021-04)   [uh oh!]
# 24,534,875 (2020-07)
# 24,393,263 (2019-12)
# 24,349,304 (2019-10)

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

# rm(bibs)
# gc()
# rm(items)
# gc()

# now using 41 GB of memory

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

# using 49 GBs of memory

comb[, .N]
# 15,715,406    (2021-04)
# 16,243,897		(2020-07)


comb[, .N, itype_dp<=100]
# 10,888,765    (2021-04)   [I guess we lost research items, too?]
# 10,895,556		(2020-07)

# but I guess it was only 6,791


  system.time(
comb %>% saveRDS("./big-sierra-comb.datatable")
  )
# 5.1 minutes


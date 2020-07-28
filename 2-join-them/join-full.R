#!/usr/bin/Rscript --vanilla

#!/usr/local/bin//Rscript --vanilla

options(echo=TRUE)

library(data.table)
library(stringr)
library(magrittr)



bibs <- fread("../1-export-from-python/bibs/exported-bibs-raw-from-python.txt",
              quote="",
              na.strings=c("NA", "", "NANA"), header=TRUE, sep="\t")

items <- fread("../1-export-from-python/items/exported-items-raw-from-python.txt",
               na.strings=c("NA", "", "NANA"), header=TRUE, sep="\t",
               colClasses=c("itemid"="character"))



bibs[, .N]
# 15,770,812 (2020-07)
# 15,525,387 (2019-12)
# 15,364,558 (2019-10)
items[, .N]
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



### IT READ THE BIBID FROM THE BIB TABLE WITH A QUOTATION MARK
# (took care of it before [2019-10])

# bibs[, bibid:=str_replace_all(bibid, '"', '')]
# setkey(bibs, "bibid")

# about 12 minutes
    system.time(
bibs %>% merge(items, all=TRUE) -> comb
    )

comb <- comb[!str_detect(item_location_str_dp, "[pc]ul")]
setcolorder(comb, c("bibid", "itemid", "inbibtable", "initemtable"))

comb %>% names

comb[bibid=="20869063"]


comb <- comb[inbibtable==TRUE]

# comb %>% fwrite("./big-comb.txt", sep="\t")

comb[, .N, itype_dp<100]
comb <- comb[!is.na(itype_dp),]

comb %>% saveRDS("./big-sierra-comb.datatable")

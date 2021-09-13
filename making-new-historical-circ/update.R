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
library(libbib)

source("~/.rix/tony-utils.R")
# ------------------------------ #


#############################################
##### THIS WILL CHANGE EACH FISCAL YEAR #####
#############################################

old <- fread("../data/historical-circ/historical-circ-fy17-19.dat.gz")

lessold <- fread("../target/sierra-all-healed-joined-2021-07-11.dat.gz",
                 select=c("bibid", "itemid", "fy17_checkouts",
                          "fy18_checkouts", "fy19_checkouts",
                          "fy20_checkouts", "fy21_checkouts"))


setnames(old, c("bibid", "itemid", "oldfy17_checkouts",
                "oldfy18_checkouts", "oldfy19_checkouts"))

setkey(old,     "itemid", "bibid")
setkey(lessold, "itemid", "bibid")

old[lessold, nomatch=NULL] -> comb


old[,.N]
lessold[,.N]
comb[,.N]

comb

comb[oldfy17_checkouts!=fy17_checkouts,.N]
comb[oldfy18_checkouts!=fy18_checkouts,.N]
comb[oldfy19_checkouts!=fy19_checkouts,.N]
comb[oldfy19_checkouts==fy20_checkouts,.N] < comb[,.N]


## debugging
# this was a book about knots that
# I took out 2020-12
comb[bibid==11315077]
comb[itemid==14021710]

comb[bibid==20869063]     # :)

comb[,oldfy17_checkouts:=NULL]
comb[,oldfy18_checkouts:=NULL]
comb[,oldfy19_checkouts:=NULL]
comb[,fy21_checkouts:=NULL]

setcolorder(comb, c("bibid", "itemid"))

rm(old)
rm(lessold)
gc()


comb %>% fwrite("../data/historical-circ/historical-circ-fy17-fy20.dat.gz")


#!/usr/bin/python3 -tt

import os
import sys
import re
import json
import fileinput



TOTAL_LINES = 36444424

# 2020-07-23:   35,327,625
# 2021-03-18:   36,444,424    (+ 1,116,800)

## QUESTION (2020-07): Why are there fewer item rows? old: 35617929

def cop_out(f):
    def inner(*args, **kargs):
        try:
            return f(*args, **kargs)
        except:
            return "NA"
    return inner


@cop_out
def get_loc_code(ajson):
    return json.loads(ajson)["code"]

@cop_out
def get_bibid(alist, itemid):
    hasmultbibids = "FALSE"
    alist = json.loads(alist)
    # if len(alist) > 1:
    #     return "NA"
    if len(alist) == 0:
        return "NA"
    if len(alist) > 1:
        efh.write("MORE THAN ONE BIB FOR ITEM: {}\n".format(itemid))
        hasmultbibids = "TRUE"
    return ('"{}"'.format(alist[0]), hasmultbibids)

@cop_out
def get_callnum(acall):
    if acall == '\\N':
        return "NA"
    if re.match("\|h", acall):
        acall = acall[2:]
    return acall

@cop_out
def get_barcode(acode):
    if acode == '\\N':
        return "NA"
    return acode

@cop_out
def get_total_checkouts(thefixedj):
    return int(thefixedj["76"]["value"])

@cop_out
def get_total_renewals(thefixedj):
    return int(thefixedj["77"]["value"])

@cop_out
def get_itype(thefixedj):
    return thefixedj["61"]["value"]

@cop_out
def get_year_to_date_circ(thefixedj):
    this = int(thefixedj["109"]["value"])
    if not this:
        return "NA"
    return "{}".format(this)

@cop_out
def get_last_years_circ(thefixedj):
    this = int(thefixedj["110"]["value"])
    if not this:
        return "NA"
    return "{}".format(this)

@cop_out
def get_created_date(thefixedj):
    tmp = thefixedj["83"]["value"]
    if not tmp:
        return "NA"
    return tmp

@cop_out
def get_total_circ(thefixedj):
    total =  get_total_checkouts(thefixedj) + get_total_renewals(thefixedj)
    return "{}".format(total)


def cop_location(apiece):
    code = "NA"
    strng = "NA"
    try:
        tmp = json.loads(apiece)
        code = tmp["code"]
        strng = tmp["name"]
    except:
        pass
    if not code:
        return ("NA", "NA")
    if not strng:
        return ("NA", "NA")
    return (code, strng)


def WRITE_IT(ofh, astr, debug=False):
    ofh.write("{}\n".format(astr))
    if debug:
        print(astr)



HEADER = '\t'.join(["itemid", "bibid_dp", "hasmultbibids",
                    "item_location_code_dp", "item_location_str_dp",
                    "barcode_dp",
                    "callnum_dp",
                    "total_checkouts_dp", "total_renewals_dp",
                    "total_circ_dp", "last_year_circ_dp",
                    "this_year_circ_dp", "itype_dp",
                    "created_date_dp"])

OUTFILE = "./exported-items-raw-from-python.txt"
ERRFILE = "./errors.txt"
ofh = open(OUTFILE, "w")
efh = open(ERRFILE, "w")


WRITE_IT(ofh, HEADER)

COUNTER = 0


for currentline in fileinput.input():
    COUNTER = COUNTER + 1
    if COUNTER % 10000 == 0:
        perc = round(COUNTER/TOTAL_LINES*100, 2)
        print("{} of {}...\t\t{}%".format(COUNTER, TOTAL_LINES, perc))

    raw_fields = currentline.split("\t")
    if len(raw_fields) != 15:
        continue

    if raw_fields[4]=="t":
        continue

    location                    = get_loc_code(raw_fields[6])
    iid                         = raw_fields[0]
    iid                         = '"{}"'.format(iid)
    bibids, hasmultbibids       = get_bibid(raw_fields[5], iid)
    barcode                     = get_barcode(raw_fields[8])
    callnum                     = get_callnum(raw_fields[9])
    try:
        fixed                   = json.loads(raw_fields[11])
    except:
        continue
    if not len(fixed):
        continue
    itype                       = get_itype(fixed)
    total_circ                  = get_total_circ(fixed)
    last_year_circ              = get_last_years_circ(fixed)
    this_year_circ              = get_year_to_date_circ(fixed)
    created_date                = get_created_date(fixed)
    total_checkouts             = "{}".format(get_total_checkouts(fixed))
    total_renewals              = "{}".format(get_total_renewals(fixed))
    locationcode, locationstr   = cop_location(raw_fields[6])


    outstr = '\t'.join([iid, bibids, hasmultbibids, locationcode,
                        locationstr, barcode, callnum, total_checkouts,
                        total_renewals, total_circ, last_year_circ,
                        this_year_circ, itype, created_date])

    WRITE_IT(ofh, outstr)


ofh.close()
print("CLOSED FILE HANDLES.... COMPLETED SUCCESSFULLY")



# 2019-12-??:       24,393,264
# 2020-07-23:       24,534,876
# 2021-03-18:       23,996,928    (uh oh)

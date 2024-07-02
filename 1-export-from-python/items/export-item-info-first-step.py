#!/usr/bin/python3 -tt

import os
import sys
import re
import json
import fileinput


TOTAL_LINES = 41357433
TOTAL_LINES = 45580834

# 2020-07-23:   35,327,625
# 2021-03-18:   36,444,424    (+ 1,116,800)
# 2021-09-09:   39,824,910    (+ 3,380,486)
# 2021-10-28:   39,964,338    (+   139,428)
# 2022-04-30:   40,683,831    (+   719,493)
# 2022-07-20:   40,983,842    (+   300,011)
# 2022-10-28:   41,357,433    (+   373,591)
# 2023-07-10:   42,143,475    (+   786,042)
# 2024-01-08:   43,912,875
# 2024-07-01:   45,580,834


DEBUG = True

SKIPPED_BECAUSE_NOT_15_FIELDS = 0
SKIPPED_BECAUSE_DELETED_ITEM = 0
SKIPPED_BECAUSE_FIXED_FIELD_CANT_LOAD = 0
SKIPPED_BECAUSE_FIXED_FIELD_HAS_NO_LENGTH = 0

LINES_EXPORTED = 0

OUTFILE = "./exported-items-raw-from-python.dat"
ERRFILE = "./item-error-log.txt"
ofh = open(OUTFILE, "w")
efh = open(ERRFILE, "w")





def debug(linenum, line, reason):
    if DEBUG:
        # print(astr, file=sys.stderr)
        efh.write("Failure on line {}\nReason: {}\nLine: {}\n\n".format(linenum, reason, line))
        efh.flush()

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
        return ("NA", hasmultbibids)
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
def get_status(thefixedj):
    tmp = thefixedj["88"]["display"]
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


def WRITE_IT(ofh, astr):
    ofh.write("{}\n".format(astr))



HEADER = '\t'.join(["itemid", "bibid_dp", "hasmultbibids",
                    "item_location_code_dp", "item_location_str_dp",
                    "barcode_dp",
                    "callnum_dp",
                    "total_checkouts_dp", "total_renewals_dp",
                    "total_circ_dp", "last_year_circ_dp",
                    "this_year_circ_dp", "itype_dp",
                    "created_date_dp", "status"])



WRITE_IT(ofh, HEADER)

COUNTER = 0


for currentline in fileinput.input():
    COUNTER = COUNTER + 1
    if COUNTER % 10000 == 0:
        perc = round(COUNTER/TOTAL_LINES*100, 2)
        print("{} of {}...\t\t{}%".format(COUNTER, TOTAL_LINES, perc))

    # NO
    # if COUNTER > 10000:
    #     break

    raw_fields = currentline.split("\t")
    if len(raw_fields) != 15:
        debug(COUNTER, currentline, "NOT length 15")
        SKIPPED_BECAUSE_NOT_15_FIELDS += 1
        continue

    if raw_fields[4]=="t":
        debug(COUNTER, currentline, "Deleted item")
        SKIPPED_BECAUSE_DELETED_ITEM += 1
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
        debug(COUNTER, currentline, "failure to load fixed fields")
        SKIPPED_BECAUSE_FIXED_FIELD_CANT_LOAD += 1
        continue
    if not len(fixed):
        debug(COUNTER, currentline, "fixed fields are empty")
        SKIPPED_BECAUSE_FIXED_FIELD_HAS_NO_LENGTH += 1
        continue
    itype                       = get_itype(fixed)
    total_circ                  = get_total_circ(fixed)
    last_year_circ              = get_last_years_circ(fixed)
    this_year_circ              = get_year_to_date_circ(fixed)
    created_date                = get_created_date(fixed)
    status                      = get_status(fixed)
    total_checkouts             = "{}".format(get_total_checkouts(fixed))
    total_renewals              = "{}".format(get_total_renewals(fixed))
    locationcode, locationstr   = cop_location(raw_fields[6])


    outstr = '\t'.join([iid, bibids, hasmultbibids, locationcode,
                        locationstr, barcode, callnum, total_checkouts,
                        total_renewals, total_circ, last_year_circ,
                        this_year_circ, itype, created_date, status])

    WRITE_IT(ofh, outstr)
    LINES_EXPORTED += 1


ofh.close()
print("CLOSED FILE HANDLES.... COMPLETED SUCCESSFULLY")


print("SKIPPED_BECAUSE_NOT_15_FIELDS:               {}".format(SKIPPED_BECAUSE_NOT_15_FIELDS))
print("SKIPPED_BECAUSE_DELETED_ITEM:                {}".format(SKIPPED_BECAUSE_DELETED_ITEM))
print("SKIPPED_BECAUSE_FIXED_FIELD_CANT_LOAD:       {}".format(SKIPPED_BECAUSE_FIXED_FIELD_CANT_LOAD))
print("SKIPPED_BECAUSE_FIXED_FIELD_HAS_NO_LENGTH:   {}".format(SKIPPED_BECAUSE_FIXED_FIELD_HAS_NO_LENGTH))
print("")
print("LINES EXPORTED:                              {}".format(LINES_EXPORTED))


# 2019-12-??:       24,393,264
# 2020-07-23:       24,534,876
# 2021-03-18:       23,996,928  (uh oh)
# 2021-07-11:       24,252,847
# 2021-09-09:       27,303,801  69.5%   (+ 3,050,954)
# 2021-10-28:       27,407,394
# 2022-04-30:       27,952,209          (+    544,815)
# 2022-07-20:       27,735,720          (-    216,489)
# 2022-10-28:       27,950,338          (+    214,618)
# 2023-07-11:       28,438,103          (+    487,765)
# 2024-01-08:       29,988,322          (+  1,550,219)
# 2024-07-01:       31,526,854          (+  1,538,532)


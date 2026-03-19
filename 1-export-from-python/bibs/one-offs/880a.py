#!/usr/bin/env -S python3 -tt

import sys
import json
import re
import fileinput


NUMBEROFLINES = 24817340

# 2019-12-??: 17582690
# 2020-07-23: 17839327	    (+   256,637)
# 2021-04-08: 18077746      (+   238,419)
# 2021-09-09: 21613873      (+ 3,536,127)
# 2021-10-28: 21712294      (+    99,521)
# 2022-04-30: 21963448      (+   251,154)
# 2022-07-20: 22053634      (+    90,186)
# 2022-10-28: 22210115      (+   156,481)
# 2023-07-10: 22548581      (+   338,466)
# 2024-01-08: 23584050      (+ 1,233,290)
# 2024-07-01: 24817340


HEADER = ["bibid", "field880_a"]



#--------------------------------------------------#

def na(val):
    if val=="":
        return "NA"
    if val=="\\N":
        return "NA"
    return val

def get_from_fixed(fixed, num, att):
    ret = "NA"
    try:
        ret = na(fixed[num][att])
    except:
        pass
    return ret

def attempt_marc_extract(func):
    def new_fn(*args, **kargs):
        the_return = "NA"
        try:
            the_return = func(*args, **kargs)
        except:
            pass
        return the_return
    return new_fn


def get_marc_tag(thefield, marcfield, subtag,
                 which_record=-1, printit=False, stripit=False,
                 nodigits=False):
    try:
        whatineed = [item for item in thefield if item["marcTag"]==marcfield]
    except:
        return "NA"
    if printit:
        print(whatineed)
    if len(whatineed) > 1 and printit:
        for item in whatineed:
            print(item)
        print("MORE THAN ONE!!!!")
    # whatineed = whatineed[which_record]
    # whatineed = whatineed["subfields"]
    tmp = []
    for item in whatineed:
        tmp.append(item["subfields"])
    whatineed = tmp
    if printit:
        print(whatineed)
    tmp = []
    for item in whatineed:
        for inner in item:
            if inner["tag"]==subtag:
                tmp.append(inner)
    tmp = [item["content"] for item in tmp]
    if printit:
        print(tmp)
    whatineed = tmp
    if stripit:
        whatineed = [item.strip() for item in whatineed]
    if nodigits:
        whatineed = [re.sub(r"\D", "", item) for item in whatineed]
    if whatineed=="":
        return "NA"
    if len(whatineed)==0:
        return "NA"
    if printit:
        print(whatineed)
    whatineed = list(set(whatineed))
    return ";".join(whatineed)


def cop_lang(apiece):
    # print(apiece)
    # return na(json.loads(apiece)["name"])
    lang = "NA"
    code = "NA"
    try:
        tmp = json.loads(apiece)
        lang = na(tmp["name"])
        code = na(tmp["code"])
    except:
        pass
    if not code:
        return ("NA", "NA")
    if not lang:
        return ("NA", "NA")
    return (code, lang)

def cop_country(apiece):
    country = "NA"
    code = "NA"
    try:
        tmp = json.loads(apiece)
        country = na(tmp["name"])
        code = na(tmp["code"])
    except:
        pass
    if not code:
        return ("NA", "NA")
    if not country:
        return ("NA", "NA")
    return (code, country)

def cop_008(var_json):
    try:
        whatineed = [item for item in var_json if item["marcTag"]=="008"]
        # if len(whatineed) != 1:
        #     print(var_json)
        #     sys.stderr.write("WWWAAAAHHHH\n")
        #     sys.stderr.flush()
        it = whatineed[0]["content"]
    except:
        it = "NA"
    return it


def cop_leader(var_json):
    try:
        whatineed = [item for item in var_json if not item["marcTag"]
                     and item["fieldTag"]=="_"]
        it = whatineed[0]["content"]
        return it
    except:
        return "NA"

def cop_standard_numbers(apiece):
    if apiece == "\\N":
        return "NA"
    try:
        tmp = json.loads(apiece)
        return ";".join(tmp)
    except:
        return "NA"

def get_all_terms_650(var_json):
    try:
        whatineed = [item for item in var_json if item["marcTag"]=="650"]
        lcsh = [item for item in whatineed if item["ind2"]=="0"]
        tmp = [item["subfields"] for item in lcsh]
        tmp = [item for sublist in tmp for item in sublist]
        topical_terms = ';'.join(list(set([item["content"] for item in tmp if item["tag"]=="a"])))
        gensubdivisions = ';'.join(list(set([item["content"] for item in tmp if item["tag"]=="x"])))
        formsubdivisions = ';'.join(list(set([item["content"] for item in tmp if item["tag"]=="v"])))
        return (na(topical_terms), na(gensubdivisions), na(formsubdivisions))
    except:
        return ("NA", "NA", "NA")

def get_geo_term(var_json):
    try:
        whatineed = [item for item in var_json if item["marcTag"]=="651"]
        lcsh = [item for item in whatineed if item["ind2"]=="0"]
        tmp = [item["subfields"] for item in lcsh]
        tmp = [item for sublist in tmp for item in sublist]
        geo_terms = ';'.join(list(set([item["content"] for item in tmp if item["tag"]=="a"])))
        return na(geo_terms)
    except:
        return "NA"

def get_copies(fixed):
    try:
        the27 = fixed["27"]
        if the27["label"]=="COPIES":
            return the27["value"]
        return "NA"
    except:
        return "NA"


def get_oclc_by_any_means_necessary(var_json):
    try:
        from001 = "NA"
        from035 = "NA"

        # 001
        these = [item for item in var_json if item["marcTag"]=="003"]
        if these and these[0]["content"]=="OCoLC":
            these = [item for item in var_json if item["marcTag"]=="001"]
            if these:
                from001 = these[0]["content"]

        # 035
        from035 = get_marc_tag(var_json, "035", "a")

        these = [item.lower() for item in from035.split(";")]
        these = [re.sub(r"\(ocolc\)\D*", "", item) for item in these if re.match(r"\(ocolc\)", item)]
        # print(these)
        # print("from 035: {}".format(from035))
        allofthem = []
        if these:
            allofthem = these
        if from001:
            allofthem = allofthem + [from001]
        allofthem = [item.strip() for item in allofthem]
        allofthem = list(set(allofthem))
        allofthem = [item for item in allofthem if item != "NA"]
        if allofthem:
            oclc = ';'.join(allofthem)
        else:
            oclc = "NA"
        return oclc
    except:
        return "NA"


#--------------------------------------------------#



JSONERRORS = 0

OUTFH = open("field880_a.dat", "w")

OUTFH.write("{}\n".format('\t'.join(HEADER)))

index = 0

for line in fileinput.input():
    index = index + 1
    good = True
    line = line.strip()

    # if index > 10000:
    #     break

    if index % 50000 == 0:
        sys.stderr.write("ON {} of {}..... {}%\n".format(
            index, NUMBEROFLINES, round((index/NUMBEROFLINES)*100, 2)))
        sys.stderr.flush()
    # we got the beat
    pieces = line.split("\t")
    THELEN = len(pieces)
    if THELEN != 24 and THELEN != 23:
        continue

    # NOT INCLUDING DELETED RECORDS
    if pieces[4]=="t":
        continue

    bibid           = pieces[0]
    bibid           = '"{}"'.format(bibid)
    fixedfields     = pieces[18]
    varfields       = pieces[19].replace("\\\\", "\\")


    # IF NO FIXED... CONTINUE
    try:
        fixed_json = json.loads(fixedfields)
        if len(fixed_json) == 0:
            continue
    except:
        continue

    try:
        var_json = json.loads(varfields)
    except:
        sys.stderr.write("ERROR WITH JSON!!!\n")
        sys.stderr.flush()
        good = False
        field880_a = "NA"



    if good:
        field880_a              = get_marc_tag(var_json, "880", "a")


    everything = [bibid, field880_a]

    try:
        OUTFH.write('\t'.join(everything).replace("\n", ""))
        OUTFH.write("\n")
    except:
        pass


# 2019-12-??:	15,525,388	88.3%
# 2020-07-23:	15,770,813	88.4%	(+   245,425)
# 2021-04-08:   15,996,120  88.4%   (+   225,307)
# 2021-09-09:   19,524,094  90.3%   (+ 3,527,974)
# 2021-10-28:   19,619,754
# 2022-04-30:   19,812,251          (+   192,497)
# 2022-07-20:   19,886,221          (+    73,970)
# 2022-10-28:   20,031,230          (+   145,009)
# 2023-07-12:   20,331,797          (+   300,567)
# 2024-01-08:   21,328,119          (+   996,322)
# 2024-07-01:   22,529,306          (+ 1,201,187)




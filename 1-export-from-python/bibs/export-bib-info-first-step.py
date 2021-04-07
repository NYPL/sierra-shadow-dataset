#!/usr/bin/env -S python3 -tt

import sys
import json
import re
import fileinput



# 2021-03-18
NUMBEROFLINES = 18060668

# 2019-12-??: 17582690
# 2020-07-23: 17839327	    (+ 256,637)
# 2021-03-18: 18060668	    (+ 221,341)


HEADER = ["bibid", "suppressed", "leader", "oh08", "source", "pub_year",
          "catalogdate", "bib_location", "biblevel", "mattype",
          "standard_nums", "isbn", "issn", "lccn", "oclc", "other_standard",
          "callnum", "lccall", "callnum2", "v852a", "langcode", "lang",
          "countrycode", "country", "publisher", "nypltype", "description1",
          "otherdetails", "dimensions", "description2", "description3",
          "norm_author", "norm_title", "author", "title",
          "num_copies_from_bib", "topical_terms", "gen_subdiv_term",
          "form_subdiv_term", "index_term", "geo_terms"]



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
        whatineed = [re.sub("\D", "", item) for item in whatineed]
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
        these = [re.sub("\(ocolc\)\D*", "", item) for item in these if re.match("\(ocolc\)", item)]
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

OUTFH = open("exported-bibs-raw-from-python.txt", "w")

OUTFH.write("{}\n".format('\t'.join(HEADER)))

index = 0

for line in fileinput.input():
    index = index + 1
    good = True
    line = line.strip()
    # if index < 103:
    #     continue
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
    source          = na(pieces[20])
    pub_year        = na(pieces[13])
    catalogdate     = na(pieces[14])
    nypltype        = na(pieces[21])

    author          = na(pieces[10])
    title           = na(pieces[9])
    norm_author     = na(pieces[17])
    norm_title      = na(pieces[16])

    suppressed      = na(pieces[6])

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
        lccn = "NA"
        oclc = "NA"
        lccall = "NA"
        tmp = "NA"
        callnum2 = "NA"
        v852a = "NA"
        callnum = "NA"
        description1 = "NA"
        description2 = "NA"
        description3 = "NA"
        otherdetails = "NA"
        dimensions = "NA"
        oh08 = "NA"
        leader = "NA"
        topical_terms = "NA"
        gen_subdiv_term = "NA"
        form_subdiv_term = "NA"
        geo_terms = "NA"
        publisherb = "NA"


    langcode, lang              = cop_lang(pieces[8])
    countrycode, country        = cop_country(pieces[15])
    standard_nums               = cop_standard_numbers(pieces[22])

    if good:
        biblevel                = get_from_fixed(fixed_json, "29", "display")
        mattype                 = get_from_fixed(fixed_json, "30", "display")
        location                = get_from_fixed(fixed_json, "26", "value")
        isbn                    = get_marc_tag(var_json, "020", "a", nodigits=True)
        issn                    = get_marc_tag(var_json, "022", "a", nodigits=True)
        other_standard          = get_marc_tag(var_json, "024", "a", nodigits=True)
        lccn                    = get_marc_tag(var_json, "010", "a", stripit=True)
        oclc                    = get_marc_tag(var_json, "035", "a")
        lccall                  = get_marc_tag(var_json, "050", "a")
        tmp                     = get_marc_tag(var_json, "050", "b")
        if tmp != "NA":
            lccall = "{} {}".format(lccall, tmp)
        callnum2                = get_marc_tag(var_json, "091", "a")
        v852a                   = get_marc_tag(var_json, "852", "a")
        callnum                 = get_marc_tag(var_json, "852", "h")
        description1            = get_marc_tag(var_json, "300", "a")
        otherdetails            = get_marc_tag(var_json, "300", "b")
        dimensions              = get_marc_tag(var_json, "300", "c")
        description2            = get_marc_tag(var_json, "310", "a")
        description3            = get_marc_tag(var_json, "362", "a")
        oh08                    = cop_008(var_json)
        leader                  = cop_leader(var_json)
        all_terms               = get_all_terms_650(var_json)
        topical_terms           = all_terms[0]
        gen_subdiv_term         = all_terms[1]
        form_subdiv_term        = all_terms[2]
        geo_terms               = get_geo_term(var_json)
        index_term              = get_marc_tag(var_json, "655", "a")
        num_copies_from_bib     = get_copies(fixed_json)
        oclc                    = get_oclc_by_any_means_necessary(var_json)
        publisherb              = get_marc_tag(var_json, "260", "b")



    everything = [bibid, suppressed, leader, oh08, source, pub_year,
                  catalogdate, location, biblevel, mattype, standard_nums,
                  isbn, issn, lccn, oclc, other_standard,
                  callnum, lccall, callnum2, v852a, langcode, lang,
                  countrycode, country, publisherb, nypltype, description1,
                  otherdetails, dimensions, description2, description3,
                  norm_author, norm_title, author, title, num_copies_from_bib,
                  topical_terms, gen_subdiv_term, form_subdiv_term, index_term,
                  geo_terms]

    try:
        OUTFH.write('\t'.join(everything).replace("\n", ""))
        OUTFH.write("\n")
    except:
        pass


# 2019-12-??:	15,525,388	88.3%
# 2020-07-23:	15,770,813	88.4%	(+ 245,425)
# 2021-03-18:   15,979,459      88.5%   (+ 208,646)



# NYPL Sierra Shadow Dataset Generation

## Introduction

[See bottom of README for a listing of columns and descriptions.](#columns-and-data-dictionary)

This is the code to join sql_dumps of the Sierra data replica postgresql
`bib` and `item` database tables. In the process, the internal JSON
fields are pulled apart and the most relevant information is extracted.
In addition, there's extensive data cleanup and consolidation, especially
with control numbers. For example, all MARC fields where the OCLC number
might live (a great deal) are interrogated and consolidated so you, dear
reader, don't have to.

## Why?

The access to the `bib` and `item` replica tables are invaluable for
understanding our collections. Prior to this, assessment types had
to create Sierra reports/list that (a) often required very computationally
expensive table joins, and (b) might have required reserving "buckets" of
a size that wasn't determinable _a priori_.

Using the replica tables directly, however, isn't a panacea, for a few
reasons...

  - Having the database hit by all interested assessment types might put
    undue stress on the server. Especially, if there's a lot of duplicated,
    or nearly identical, queries.

  - Columns of JSON type (while absolutely awesome) are difficult for
    users used to traditional RDB SQL to work with, and almost always
    requires post-query manipulation, anyway.

__Most importantly...__

  - The `item` and `bib` tables live in different PostgreSQL servers.
    So, in order to, say, get circulation (item info) statistics for all
    items in a certain language, or within a certain subject (bib
    information), the tables can't be joined on `itemid` within one database
    cluster. Instead, essentially, all required columns from each table
    would have to be queried, save, and joined on the user's local machine.

Given that the need to join item and bib information is so high, it makes
sense to, at periodic intervals, perform an `sql_dump` on each table and
join it once and share it with all interested parties.

Although the `sql_dump` is an expensive operation, this only has to be
done once every once in a while. The end result is _much_ less strenuous
for the servers _and_ much easier for the person doing the assessment.

It should be noted that the sql exports total over 100GB and joining
all this data will easily outstrip all the RAM available on commodity
hardware. Each time this process this process (in the repo) is run, it
requires provisioning a AWS EC2 instance with at least 64GB of RAM.
But, as mentioned, this only has to be done once and everybody can share
it.

Finally, in order to get the most complete bibliographic metadata, some
(a) really arcane MARC know-how has to be used, and (b) a fair bit of
institution-specific knowledge about the idiosyncracies of our metadata
is required. For example, the OCLC number can (as is) stored in no fewer
than three different MARC fields. The appropriate number may be stored in
any one (or none) of these locations.

As we learn more, and consult with metadata experts, appropriate changes
and extentions can by made to this code and we can all benefit from the
same MARC field interrogations and manipulations.


## Where can I get the dataset(s)?
It lives on a shared NYPL drive named `NYPL Shadow Dataset`.
There you'll find...

  - `sierra-all-healed-joined.datatable` a serialized R datatable object
    containing both research and branch items.

  - `sierra-branch-healed-joined.datatable` a serialized R datatable object
    containing both just branch items as determined by the ITYPE. This
    is _substantially_ smaller than the full or research counterpart.

  - `sierra-research-healed-joined.datatable` a serialized R datatable object
    containing both just research items as determined by the ITYPE

  - `sierra-bib-dump.sql.gz` a gzipped copy of the postgres BIB database
    dump straight from the source

  - `sierra-item-dump.sql.gz` a gzipped copy of the postgres ITEM database
    dump straight from the source

  - a copy of the latest historical circ information used in the process
    for joining with with the dumps to include circ counts from previous
    years. At time of writing, this is a 4 column (serialized) dataset
    including `bibid`, `itemid`, `fy17_checkouts`, and `fy18_checkouts`.
    When joined with the lasted aggregation, for example, this will
    yield FY17-to-FY20 circ information for every NYPL item

All of the files above include the date of the database(s) export before
the file extension. As of time of writing this is __2020-07-23__.

The serialized (and heavily compressed) `.datatable` files can be read
from R using the following incantation in R:

```
whatever <- readRDS("./thefile.datatable")
```

Other formats may be included if other people find that it would be useful.
(Heavily) compressed CSV/TSV, feather, sqlite file, whatever.

## Development stack

The following R packages are needed

  - data.table
  - magrittr
  - pbapply
  - stringr
  - colorout (optional)

The two python sripts are Python 3. They use the `sys`, `json`, `re`,
and `fileinput` modules. These should be included with Python 3

To build this completely from scratch (from the sqldumps), various
unix/coreutils tools were used and a postgresql client is needed.

## Organization of git repo

Each step has a separate folder and must be run sequentially.
Note that Step 4 is including in Step 3's folder.

This repo will branch from master for each sqldump and be named after
the date of export. Git tags will also be used for "releases"

To make the git history tidy, `git commit --amend`s may be
used. If this causes a problem with your local copy, `format-patch -N?`
back to the departure point  and reapply it to a fresh copy of the
upstream repository.


Step 1
-----
This first step consumes the sqldumps and does most of the teasing apart
of the most relevant information.

The bib and item scripts (which are separated) consume data, line-by-line,
from standard input. This obviates the need to read and store the whole
file in memory, and uses very little RAM.

The data can be fed into the scripts directly from the gzipped SQL dumps
like so...

```
$ zcat sierra-bib-dump-2020-07-23.sql.gz | ./export-bib-info-first-step.py
$ # and similar for the item dump
```

These is a crude progress indicator for each script.

At the end, two files (`exported-bibs-raw-from-python.txt` and
`exported-items-raw-from-python.txt`) are spit out and ready to be consumed
by the process in the next stage.


Step 2
-----
This consumes the two exports from the previous step, does a little bit
of filtering, and joins the two data tables on `itemid`. This is the
step that requires a special memory-optimized EC2 instance to run.

The output is `bib-sierra-comb.datatable`.


Step 3 (and 4)
-----
In step 3, the ISBNs (converted to ISBN13s) and ISSN are remediated and
verified. The process is parallelized (using the `pbapply` package) but
still takes over 30 min to run using 6 threads.

Step 4 remediates the LCCN and OCLC numbers, and joins the remediated ISBNs
and ISSNs back in. If there are multiple control numbers for any of these
types, they are deduplicated and the unique numbers are joined and delimited
by semicolons.

`big-healed-sierra-comb.datatable` is ready for the final stage.

Step 5
-----
This last stage joins previous years' circulation data into the mix. At
time of writing, FY17 and FY18 circulation numbers are thrown in with the
complete FY19 and FY20 numbers, creating four consecutive years with
by-year circulation information. 

Additionally, all of the items under each `bibid` have all of their
circulation numbers summed. This means, that for each row (unique `bibid`
and `itemid`) we have the circulation data for the specific item _and_
the circulation data for the title. The latter numbers are, of course,
identical for each item under the title. This is especially useful for
serials and branch titles.


## Columns and data dictionary

  - `bibid`

  - `itemid`

  - `inbibtable`

    Since the bib and item table or joined, its possible for
    some bibid not to have matching items, and vice-versa
  - `initemtable`

    Since the bib and item table or joined, its possible for
    some bibid not to have matching items, and vice-versa

  - `suppressed`

  - `itype`

  - `branch_or_research`

    This is determined by whether the ITYPE is above or below 100

  - `is_mixed_bib`


    Whether there are items under the bib that are both research and branch

  - `leader`

    The MARC leader which [is very rich in information](https://www.loc.gov/marc/bibliographic/bdleader.html)

  - `oh08`

    The MARC 008 fixed field which [is extremely rich in information](https://www.loc.gov/marc/bibliographic/bd008.html)

  - `source`

    Just `sierra-nypl` for now but may include parter records later.

  - `pub_year`

    Beware that some of these are 9999 and lower than 199. This cannot be rectified without further information (TODO)

  - `catalogdate`

  - `bib_location`

    You almost certainly want `item_location_code` or `item_location_str` instead. Future version may remove this field (TODO)

  - `biblevel`

    MONOGRAPH, SERIAL, ARCHIVES & MSS, etc...

  - `mattype`

    BOOK/TEXT, SCORE, MICROFORM, etc...

  - `standard_nums`

    Non-specific "standard numbers". Don't trust these.

  - `isbn`

    ISBNs. Converted to ISBN-13, deduplicated, cleaned, and check-digit confirmed.

  - `issn`

    ISSNs. Deduplicated, cleaned, and check-digit confirmed. No hyphen

  - `lccn`

    Normalized 12-digit LCCN. No revision numbers. 48% present [more info](https://www.loc.gov/marc/lccn_structure.html)

  - `oclc`

    OCLC number. 65% present

  - `other_standard`

    Miscellaneous other control numbers. Don't trust these.

  - `callnum`

    __NYPL__ call number. Included Billings, Fixed order, etc...

  - `lccall`

    Library of Congress call number. [Can be used for subject analysis.](https://www.loc.gov/catdir/cpso/lcco/) 56% present.

  - `callnum2`

    Dewey/branch call numbers. 99.7% present for branch items. [Can be used for subject analysis](https://www.oclc.org/content/dam/oclc/dewey/resources/summaries/deweysummaries.pdf)

  - `v852a`

  - `langcode`

    [Language code](https://www.loc.gov/marc/languages/language_code.html)

  - `lang`

    [Language name](https://www.loc.gov/marc/languages/language_code.html)

  - `countrycode`

    [country code](https://www.loc.gov/marc/countries/countries_code.html)

  - `country`

    [country name](https://www.loc.gov/marc/countries/countries_code.html])

  - `pubisher`

    This is misspelled. This will be fixed in the next release (TODO)

  - `nypltype`

    Always "bib". May be removed in future (TODO)

  - `description1`

    MARC field 300\$a [physical description](https://www.loc.gov/marc/bibliographic/bd300.html)

  - `otherdetails`

    MARC field 300\$b [physical description](https://www.loc.gov/marc/bibliographic/bd300.html)

  - `dimensions`

    MARC field 300\$c [physical description](https://www.loc.gov/marc/bibliographic/bd300.html)

  - `description2`

    MARC field 310\$a [publication frequency](https://www.loc.gov/marc/bibliographic/bd310.html)

  - `description3`

    MARC field 360\$ (pub dates or sequential designation)[https://www.loc.gov/marc/bibliographic/bd362.html]. Great for serials.

  - `norm_author`

    Normalized author

  - `norm_title`

    Normalized title

  - `author`

  - `title`

  - `num_copies_from_bib`

    A fixed field in database. Not sure what it is.

  - `topical_terms`

    Semicolon-delimited list of topical terms (MARC 650\$a). [See this page for more info](https://www.loc.gov/marc/bibliographic/bd650.html)

  - `gen_subdiv_term`

    Semicolon-delimited list of general subdivisions (MARC 650\$x). [See this page for more info](https://www.loc.gov/marc/bibliographic/bd650.html)

  - `form_subdiv_term`

    Semicolon-delimited list of form subdivisions (MARC 650\$v). [See this page for more info](https://www.loc.gov/marc/bibliographic/bd650.html)

  - `index_term`

    Index term, genre/form (MARC 655\$a) [See this page for more info](https://www.loc.gov/marc/bibliographic/bd655.html)

  - `geo_terms`

    Geographical terms (MARC 651\$a) [See this page for more info](https://www.loc.gov/marc/bibliographic/bd651.html)

  - `hasmultbibids`

    Does the item have multiple bibids?

  - `item_location_code`

  - `item_location_str`

  - `barcode`

  - `item_callnum`

    Another place where the __NYPL__ call number may be

  - `created_date`

  - `total_checkouts`

  - `total_renewals`

  - `total_circ`

    total checkouts + total renewals

  - `fy17_checkouts`

  - `fy18_checkouts`

  - `fy19_checkouts`

  - `fy20_checkouts`

  - `bib_fy17_checkouts`

    Sum of FY17 checkouts for all items under bibid (very useful)

  - `bib_fy18_checkouts`

    Sum of FY18 checkouts for all items under bibid (very useful)

  - `bib_fy19_checkouts`

    Sum of FY19 checkouts for all items under bibid (very useful)

  - `bib_fy20_checkouts`

    Sum of FY20 checkouts for all items under bibid (very useful)

  - `bib_total_checkouts`

    Sum of total checkouts for all items under bibid (very useful)

  - `bib_total_renewals`

    Sum of total renewals for all items under bibid (very useful)

  - `bib_total_circ`

    Sum of total checkouts __and__ renewals for all items under bibid (very useful)



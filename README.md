
# NYPL Shadow Dataset Generation

## Introduction

[See bottom of README for a listing of columns and descriptions.](#columns-and-data-dictionary)

## Why?

## Where an I get the dataset(s)?
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
the file extension. As of time of writing this is 2020-07-23.

The serialized (and heavily compressed) `.datatable` files can be read
from R using the following incantation

```
whatever <- readRDS("./thefile.datatable")
```

Other formats may be included if other people find that it would be useful.

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
stub


Step 2
-----
stub


Step 3 (and 4)
-----
stub


Step 5
-----
stub


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
  - `pub_year`
  - `catalogdate`
  - `bib_location`
  - `biblevel`
  - `mattype`
  - `standard_nums`
  - `isbn`
  - `issn`
  - `lccn`
  - `oclc`
  - `other_standard`
  - `callnum`
  - `lccall`
  - `callnum2`
  - `v852a`
  - `langcode`
  - `lang`
  - `countrycode`
  - `country`
  - `pubisher`
  - `nypltype`
  - `description1`
  - `otherdetails`
  - `dimensions`
  - `description2`
  - `description3`
  - `norm_author`
  - `norm_title`
  - `author`
  - `title`
  - `num_copies_from_bib`
  - `topical_terms`
  - `gen_subdiv_term`
  - `form_subdiv_term`
  - `index_term`
  - `geo_terms`
  - `hasmultbibids`
  - `item_location_code`
  - `item_location_str`
  - `barcode`
  - `item_callnum`
  - `created_date`
  - `total_checkouts`
  - `total_renewals`
  - `total_circ`
  - `fy17_checkouts`
  - `fy18_checkouts`
  - `fy19_checkouts`
  - `fy20_checkouts`
  - `bib_fy17_checkouts`
  - `bib_fy18_checkouts`
  - `bib_fy19_checkouts`
  - `bib_fy20_checkouts`
  - `bib_total_checkouts`
  - `bib_total_renewals`
  - `bib_total_circ`




# NYPL Shadow Dataset Generation

## Introduction

## Why?

## Where an I get the dataset(s)?
It lives on a shared NYPL drive named `NYPL Shadow Dataset`.
There you'll find...

  - `sierra-all-healed-joined.datatable` a serialized R datatable object
    containing both research and branch items.

  - `sierra-branch-healed-joined.datatable` a serialized R datatable object
    containing both just branch items as determined by the ITYPE

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


## Organization of git repo


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


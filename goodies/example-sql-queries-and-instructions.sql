
----------------------------------------------------------------
-- some example queries for running right on the shadow db... --
----------------------------------------------------------------

-- first connect to the NYPL network using a VPN
-- then, connect to the DB using `psql`... (incantation below uses item db/table)
--   psql --host="item-service-production-rep.cvy7z512hcjg.us-east-1.rds.amazonaws.com"
--   --port=5432 --dbname="item_service_production" --table=item --user=YOUR-USERNAME
--   then put in your password
-- try out these examples (using the item DB and table)

select barcode from item limit 7;

select var_fields from item limit 1;

-- pulls out fixed field 88
select fixed_fields->'88' as this from item limit 2;

-- get the display value of the 88 fixed field
select fixed_fields#>'{88,display}' as this from item limit 2;

-- get the value subfield of the 88 fixed field (as string) [not json]
select fixed_fields#>>'{68,value}' as this from item limit 27;

-- get itemid, barcode, last check-in and status only for items
-- last checked-in since 2021-10-03 (inclusive)
select id,
       barcode,
       fixed_fields#>>'{68,value}' as lastcheckin,
       fixed_fields#>'{88,display}' as status
    from item
    where (fixed_fields#>>'{68,value}') > '2021-10-03';
    limit 100;


---- For any of these queries (and others, of course) you can save
--   them as an SQL file, run it right on the shadow db server
--   from your local machine, and get a csv of the results _back_
--   to your local machine with this incantation...

--   psql --host="item-service-production-rep.cvy7z512hcjg.us-east-1.rds.amazonaws.com"
--   --port=5432 --dbname="item_service_production" --table=item --user=YOURUSERNAME
--   -f MYSQLFILE.sql -A  -t -F"," -o MYOUTPUTFILE.csv

--   The arcane command line flags above set options that make the output file
--   readily consumable by R, excel, etc...
--   -F, for example, sets the field separator


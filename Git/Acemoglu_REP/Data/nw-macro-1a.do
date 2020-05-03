#delimit;
cap n log close; 
cd /export/projects/wkerr_ethnicity_project/networks/macro/replication;
log using nw-macro-1a.log, replace; 

* William Kerr, TGG;
* Data Grid Preparation;
* stata-mp8-20g -b do nw-macro-1a.do;
* Last Modified: May 2015;

clear all; set matsize 5000; set more off;

local znber3 *nber_emp *nber_vadd *nber_rvadd *nber_lprod *nber_rlprod;

**************************;
*** Grid prep           **;
**************************;

*** Prepare symmetric grid;
use ./raw/main_annual_format, clear; des; sum;
keep year; duplicates drop; sort year; save ./temp/list-year, replace; sum;
use ./raw/main_annual_format, clear; 
keep sic87dd; duplicates drop; sort sic87dd; save ./temp/list-sic87dd, replace; sum;
ren sic87dd sic87dd_up; cross using ./temp/list-sic87dd; ren sic87dd sic87dd_down; 
cross using ./temp/list-year; sort sic87dd_up sic87dd_down year; 
save ./temp/sic87-year-grid, replace; sum;

*** Create NBER inputs file;
use ./raw/main_annual_format; des;
collapse (mean) nber_emp nber_nom_vadd nber_nom_vship nber_piship, by(sic87dd year) fast;
sort sic87dd year; save ./temp/nber-inputs, replace;

*** Merge in annual data for both industries;
use ./temp/sic87-year-grid, clear; sum;
ren sic87dd_up sic87dd; sort sic87dd year;
merge sic87dd year using ./temp/nber-inputs; assert _m==3; drop _m;
rename _all U=; ren Usic87dd sic87dd_up; ren Uyear year; 
ren Usic87dd_down sic87dd; sort sic87dd year;
merge sic87dd year using ./temp/nber-inputs; assert _m==3; drop _m;
rename _all D=; renpfix DU U; 
ren Dsic87dd_up sic87dd_up; ren Dsic87dd sic87dd_down; ren Dyear year; 
for any U D: gen Xnber_vadd=Xnber_nom_vadd; 
for any U D: gen Xnber_rvadd=Xnber_nom_vadd/Xnber_piship; 
for any U D: gen Xnber_sales=Xnber_nom_vship; 
for any U D: gen Xnber_rsales=Xnber_nom_vship/Xnber_piship; 
for any U D: gen Xnber_lprod=Xnber_vadd/Xnber_emp;
for any U D: gen Xnber_rlprod=Xnber_rvadd/Xnber_emp;
drop *nom*;
compress; sort sic87dd_up sic87dd_down year; save ./temp/sic87-year-grid-full, replace; sum;

*** Prepare SIC3-level grid for key variables;
use ./temp/sic87-year-grid-full, clear;
gen Usic3=int(sic87dd_up/10); gen Dsic3=int(sic87dd_down/10); 
collapse (sum) *nber_emp *nber_vadd *nber_rvadd *nber_sales *nber_rsales, by(Usic3 Dsic3 year) fast;
for any U D: gen Xnber_lprod=Xnber_vadd/Xnber_emp;
for any U D: gen Xnber_rlprod=Xnber_rvadd/Xnber_emp;
compress; sort Usic3 Dsic3 year; save ./temp/sic87-year-grid-sic3, replace; sum; 
keep if year==1991; drop year;
compress; sort Usic3 Dsic3; save ./temp/sic87-year-grid-sic3-1991, replace; sum; 

**************************;
*** Input-output flows  **;
**************************;

*** Combine input-output matrices;
* gross_flows ~ Value of gross flows from upstream to downstream in 1992;
* tot_sales_down ~ Total sales by sic87dd_down;
* tot_sales_up ~ Total sales by sic87dd_up;
* produce_share ~ Share of sic87dd_up's sales that go to sic87dd_down;
* purchase_share ~ Cost share of sic87dd_up's good in sic87dd_down's production;
use ./raw/gross_shares, clear; des; sum;
ren produce_share produce_shareD; ren purchase_share purchase_shareD;
sort sic87dd_down sic87dd_up; merge sic87dd_down sic87dd_up using ./raw/leontief_down.dta, nok; tab _m; drop _m;
sort sic87dd_up sic87dd_down; merge sic87dd_up sic87dd_down using ./raw/leontief_up.dta, nok; tab _m; drop _m;
ren produce_share produce_shareL; ren purchase_share purchase_shareL;
keep if (sic87dd_down>=2000 & sic87dd_down<=3999) & (sic87dd_up>=2000 & sic87dd_up<=3999);

*** Prepare flow matrix;
gen io_perc_up=gross_flows/tot_sales_up; 
gen io_perc_down=gross_flows/tot_sales_down;
pwcorr produce* purchase* io_perc*; drop produce_shareD purchase_shareD;
egen temp1=sum(io_perc_up), by(sic87dd_up); gen io_nperc_up=io_perc_up/temp1; drop temp1; 
egen temp1=sum(io_perc_down), by(sic87dd_down); gen io_nperc_down=io_perc_down/temp1; drop temp1; 
ren produce_shareL io_Lperc_up; ren purchase_shareL io_Lperc_down;
compress; sort sic87dd_up sic87dd_down; save ./temp/io-grid-sort, replace; sum;

**************************;
*** Geographic flows    **;
**************************;

*** Prepare aak geographic proximity matrix - sic87dd czone emp year;
use sic87dd czone emp if (sic87dd>=2000 & sic87dd<=3999) using ./raw/cbp_czone_1991, clear;
sort sic87dd czone; save ./temp/aak1, replace; sum;
keep sic87dd; duplicates drop; sort sic87dd; save ./temp/aak1b, replace;
use ./temp/aak1, clear; 
egen empr=sum(emp), by(czone);
egen empi=sum(emp), by(sic87dd);
for var sic87dd emp: ren X X1;
cross using ./temp/aak1b;
sort sic87dd czone; merge sic87dd czone using ./temp/aak1; assert _m==3; drop _m;
for var sic87dd emp: ren X X2; 
gen geo12=emp1*emp2/(empr*empi);
collapse (sum) geo12, by(sic87dd1 sic87dd2) fast;
ren sic87dd1 sic87dd_down; ren sic87dd2 sic87dd_up;
compress; sort sic87dd_up sic87dd_down; save ./temp/aak-grid-sort, replace;
sum; for any 1 1b: erase ./temp/aakX.dta;

*** Geographic HHI;
use sic87dd czone emp if (sic87dd>=2000 & sic87dd<=3999) using ./raw/cbp_czone_1991, clear;
egen temp1=sum(emp), by(sic87dd);
gen hhi=(emp/temp1)^2;
collapse (sum) hhi, by(sic87dd) fast;
compress; sort sic87dd; save ./temp/sic87-hhi, replace;

**************************;
*** 2nd Order Terms    **;
**************************;

/* Created intermediate file copied into raw folder for replication due to memory/time requirements...
*** Prepare aak geographic proximity matrix for higher-order terms;
use sic87dd czone emp if (sic87dd>=2000 & sic87dd<=3999) using ./raw/cbp_czone_1991, clear;
egen czone2=group(czone); drop czone; ren czone2 czone;
sort sic87dd czone; compress; save ./temp/aak1, replace; sum;
keep sic87dd; duplicates drop; sort sic87dd; compress; save ./temp/aak1b, replace;
keep if sic87dd<3000; sort sic87dd; compress; save ./temp/aak1b1, replace;
use ./temp/aak1b, clear; keep if sic87dd>=3000; sort sic87dd; compress; save ./temp/aak1b2, replace;

use ./temp/aak1, clear; 
egen empr=sum(emp), by(czone);
egen empi=sum(emp), by(sic87dd);
gen geo123=emp/(empr*empr*empi);
drop if geo123==0; drop if emp<20;
drop emp empr empi; ren sic87dd sic87dd1; compress;

cross using ./temp/aak1b; 
sort sic87dd czone; merge sic87dd czone using ./temp/aak1, nok; drop _m;
replace geo123=geo123*emp; drop if geo123==0; drop if emp<20; drop emp;
for var sic87dd: ren X X2; sum; compress;
save aak2a, replace;

cross using ./temp/aak1b1; 
sort sic87dd czone; merge sic87dd czone using ./temp/aak1, nok; drop _m;
replace geo123=geo123*emp; drop if geo123==0; drop if emp<20; drop emp;
for var sic87dd: ren X X3; sum; compress;
collapse (sum) geo123, by(sic87dd1 sic87dd2 sic87dd3) fast;
compress; save aak2b, replace;

use aak2a, clear;
cross using ./temp/aak1b2; 
sort sic87dd czone; merge sic87dd czone using ./temp/aak1, nok; drop _m;
replace geo123=geo123*emp; drop if geo123==0; drop if emp<20; drop emp;
for var sic87dd: ren X X3; sum; compress;
collapse (sum) geo123, by(sic87dd1 sic87dd2 sic87dd3) fast;
compress; append using aak2b;

fillin sic87dd1 sic87dd2 sic87dd3; tab _f; drop _f;
replace geo123=0 if geo123==.;
sort sic87dd1 sic87dd2 sic87dd3; save ./temp/aak-grid-sort-ext, replace; sum;
for any 2a 2b: erase aakX.dta;
for any 1 1b 1b2: erase ./temp/aakX.dta;

use ./temp/aak-grid-sort-ext, clear; 
drop if (sic87dd1==sic87dd2 | sic87dd1==sic87dd3 | sic87dd2==sic87dd3);
collapse (sum) geo123, by(sic87dd1 sic87dd3) fast;
ren sic87dd1 sic87dd_down; ren sic87dd3 sic87dd_up;
sort sic87dd_up sic87dd_down; save ./temp/aak-grid-sort-ext-sum, replace; sum; */

*****************************;
*** Interlinkages Combined **;
*****************************;

*** Open industry pair grid;
use ./temp/sic87-year-grid-full, clear; 
keep if year==2000; drop year;

*** Merge in matrices and save;
sort sic87dd_up sic87dd_down; merge sic87dd_up sic87dd_down using ./temp/io-grid-sort, nok; assert _m==3; drop _m;
sort sic87dd_up sic87dd_down; merge sic87dd_up sic87dd_down using ./temp/aak-grid-sort, nok; assert _m==3; drop _m; 
sort sic87dd_up sic87dd_down; merge sic87dd_up sic87dd_down using ./raw/aak-grid-sort-ext-sum; tab _m; drop _m;
compress; sort sic87dd_up sic87dd_down; save ./temp/combined-networks, replace;

*** End of program;
log close;

**************************;
**************************;
*** SAVE MATERIALS      **;
**************************;
**************************;
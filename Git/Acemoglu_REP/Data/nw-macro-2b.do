#delimit;
cap n log close; 
cd /export/projects/wkerr_ethnicity_project/networks/macro/replication;
log using nw-macro-2b.log, replace; 

* William Kerr, To God's Glory;
* Extension to Consider Resource Constraint;
* stata-mp8-10g -b do nw-macro-2b.do;
* Last Modified: May 2015;

clear all; set matsize 5000; set more off;

local znber nber_emp nber_vadd nber_rvadd nber_sales nber_rsales nber_lprod nber_rlprod;
local znber2 nber_emp* nber_vadd* nber_rvadd* nber_sales* nber_rsales* nber_lprod* nber_rlprod*;
local znber3 *nber_emp *nber_vadd *nber_rvadd *nber_sales *nber_rsales *nber_lprod *nber_rlprod;
local znberT nber_rvadd nber_emp;
local trade l_import_usch l_import_otch;
local SHOCK zlnber_rvadd zlnber_sales zlnber_rsales zlnber_emp lnber_rvadd lnber_emp lnber_rlprod l_import_usch l_import_otch esfed ltfp4 ltfp5 lfmct lfuct;
local GEO GAD;
local LB 0.1;
local UB 99.9;
local SH l_import_otch;

**************************;
**************************;
*** Prepare Resource    **;
**************************;
**************************;

*** Prepare federal spending shock entry;
use ./raw/all_sales, clear; 
sort sic87dd; merge sic87dd using ./temp/list-sic87dd; tab _m; gen mfg=(_m==3);
gen gov=def_sales+nondef_sales; gen mgov=gov if mfg==1; gen temp1=1;
collapse (sum) gov mgov, by(temp1) fast;
gen ratio=mgov/gov; sum ratio;
use ./temp/list-year, clear; duplicates drop;
replace year=year-1;
for any def fed: gen spX=.;
replace spdef=281889 if year==1988;	replace spfed=1064416 if year==1988;
replace spdef=294829 if year==1989;	replace spfed=1143744 if year==1989;
replace spdef=289694 if year==1990;	replace spfed=1252993 if year==1990;
replace spdef=261860 if year==1991;	replace spfed=1324226 if year==1991;
replace spdef=286574 if year==1992;	replace spfed=1381529 if year==1992;
replace spdef=278510 if year==1993;	replace spfed=1409386 if year==1993;
replace spdef=268577 if year==1994;	replace spfed=1461753 if year==1994;
replace spdef=259487 if year==1995;	replace spfed=1515742 if year==1995;
replace spdef=253196 if year==1996;	replace spfed=1560484 if year==1996;
replace spdef=258262 if year==1997;	replace spfed=1601116 if year==1997;
replace spdef=255793 if year==1998;	replace spfed=1652458 if year==1998;
replace spdef=261196 if year==1999;	replace spfed=1701842 if year==1999;
replace spdef=281028 if year==2000;	replace spfed=1788950 if year==2000;
replace spdef=290185 if year==2001;	replace spfed=1862846 if year==2001;
replace spdef=331845 if year==2002;	replace spfed=2010894 if year==2002;
replace spdef=388686 if year==2003;	replace spfed=2159899 if year==2003;
replace spdef=437034 if year==2004;	replace spfed=2292841 if year==2004;
replace spdef=474354 if year==2005;	replace spfed=2471957 if year==2005;
replace spdef=499344 if year==2006;	replace spfed=2655050 if year==2006;
replace spdef=528578 if year==2007;	replace spfed=2728686 if year==2007;
replace spdef=594662 if year==2008;	replace spfed=2982544 if year==2008;
replace spdef=636775 if year==2009;	replace spfed=3517677 if year==2009;
replace spdef=666715 if year==2010;	replace spfed=3457079 if year==2010;
replace spdef=678074 if year==2011;	replace spfed=3603059 if year==2011;
replace spdef=650867 if year==2012;	replace spfed=3537127 if year==2012;
replace spdef=607800 if year==2013;	replace spfed=3454605 if year==2013;
replace year=year+1;
sort year; 
for var sp*: replace X=X*1000000*.243655 \ gen DX=X-X[_n-1];
compress;
save ./temp/federal-annual, replace;

*** Generate complete import sequence;
use if exporter=="CHN" using ./raw/sic87dd_trade_data, clear;
sort year; merge year using ./raw/pce, nok; tab _m; drop _m; 
gen impus=imports*pce if importer=="USA";
gen impot=imports*pce if importer=="OTH";
collapse (sum) impus impot, by(year) fast;
sort year;
for var imp*: gen DX=X-X[_n-1];
save ./temp/trade-annual, replace;

*** Combine together;
use sic87dd year nber_vadd lnber_sales using ./temp/shock-baselines, clear; 
gen nber_sales=exp(lnber_sales); drop lnber_sales; drop if nber_sales==.;
collapse (sum) nber_sales, by(year) fast;
sort year; merge year using ./temp/federal-annual, nok; tab _m; drop _m;
sort year; merge year using ./temp/trade-annual, nok; tab _m; drop _m;
keep year Dimpus Dimpot Dspfed; for var D*: ren X AX;
sort year; save ./temp/resourcemerger, replace;

**************************;
**************************;
*** Prepare Shocks      **;
**************************;
**************************;

forvalues i=1(1)1 {;

*** Open data and recode year;
use ./temp/shock-baselines, clear; 
recode year 1991=1 1993=2 1995=3 1997=4 1999=5 2001=6 2003=7 2005=8 2007=9 2009=10 if `i'==2; 
recode year 1991=1 1994=2 1997=3 2000=4 2003=5 2006=6 2009=7 if `i'==3; 
recode year 1991=1 1995=2 1999=3 2003=4 2007=5 if `i'==4; 
recode year 1991=1 1996=2 2001=3 2006=4 if `i'==5;
gen dropped=(year>10); replace dropped=0 if `i'==1; keep if dropped==0; drop dropped;

*** Prepare differences for network analysis;
tsset sic87dd year;
for var lnber_rvadd lnber_sales lnber_rsales lnber_emp: gen zX=X;
for var zlnber_rvadd zlnber_sales zlnber_rsales zlnber_emp l_import_usch l_import_otch esfed ltfp4 ltfp5 lfmct lfuct: 
\ gen DX=X-l1.X \ egen temp1=sd(DX) \ replace DX=DX/temp1 \ drop temp1;
for var lnber*: gen DX=X-l1.X;
for var D*: 
\ egen temp1=pctile(X), p(`LB') \ egen temp2=pctile(X), p(`UB')
\ replace X=temp1 if X<temp1 \ replace X=temp2 if X>temp2 & X!=. \ drop temp*;
sort sic87dd year; save ./temp/shock-baselines-temp, replace;

*** Merge grids, trade data, productivity data, and spending data - upstream;
use sic87dd_up sic87dd_down year using ./temp/sic87-year-grid-full, clear; 
recode year 1991=1 1993=2 1995=3 1997=4 1999=5 2001=6 2003=7 2005=8 2007=9 2009=10 if `i'==2; 
recode year 1991=1 1994=2 1997=3 2000=4 2003=5 2006=6 2009=7 if `i'==3; 
recode year 1991=1 1995=2 1999=3 2003=4 2007=5 if `i'==4; 
recode year 1991=1 1996=2 2001=3 2006=4 if `i'==5;
gen dropped=(year>10); replace dropped=0 if `i'==1; keep if dropped==0; drop dropped; tab year;
ren sic87dd_up sic87dd; sort sic87dd year; merge sic87dd year using ./temp/shock-baselines-temp, keep(D*) nok; assert _m==3; drop _m; renpfix D UD; ren sic87dd sic87dd_up; 
ren sic87dd_down sic87dd; sort sic87dd year; merge sic87dd year using ./temp/shock-baselines-temp, keep(D*) nok; assert _m==3; drop _m; renpfix D DD; ren sic87dd sic87dd_down;

*** Merge networks;
sort sic87dd_up sic87dd_down; merge sic87dd_up sic87dd_down using ./temp/combined-networks, nok; tab _m; keep if _m==3; drop _m;
for var geo12 geo123: replace X=. if sic87dd_up==sic87dd_down;
sort sic87dd_up sic87dd_down; save ./temp/sic87-year-grid-temp2b, replace;

*** Prepare contemporaneous upstream stimulus;
for any `SHOCK': 
\ gen ZTFUX=UDX*io_perc_down
\ gen ZTLUX=UDX*io_Lperc_down
\ gen ZDLUX=UDX*(1+io_Lperc_down) if sic87dd_up==sic87dd_down
\ gen ZNLUX=UDX*io_Lperc_down if sic87dd_up!=sic87dd_down
\ gen GAUX=UDX*geo12
\ gen GHUX=UDX*geo123;
collapse (sum) Z* G*, by(sic87dd_down year) fast; ren sic87dd sic87dd;
sort sic87dd year; save ./temp/sh-tr-upstream, replace;

*** Prepare contemporaneous downstream stimulus;
use ./temp/sic87-year-grid-temp2b, clear;
sort year; merge year using ./temp/resourcemerger; tab _m; drop _m;
egen temp1=sum(Dnber_vadd); egen temp2=sum(Dnber_vadd), by(sic87dd_down); gen MULT=temp2/temp1; su MULT; drop temp*;
gen RLI=io_Lperc_up; replace RLI=RLI+1 if sic87dd_up==sic87dd_down;
for any `SHOCK': 
\ gen ZTFDX=DDX*io_perc_up
\ gen ZTLDX=DDX*io_Lperc_up
\ gen ZDLDX=DDX*(1+io_Lperc_up) if sic87dd_up==sic87dd_down
\ gen ZNLDX=DDX*io_Lperc_up if sic87dd_up!=sic87dd_down
\ gen GADX=DDX*geo12
\ gen GHDX=DDX*geo123;

gen ZR4LDl_import_usch=ADimpus/Dnber_vadd*RLI*MULT;
gen ZR4LDl_import_otch=ADimpot/Dnber_vadd*RLI*MULT;
gen ZR4LDesfed=ADspfed/Dnber_vadd*RLI*MULT;

collapse (sum) Z* G*, by(sic87dd_up year) fast; ren sic87dd sic87dd;
sort sic87dd year; merge sic87dd year using ./temp/sh-tr-upstream; assert _m==3; drop _m;
sort sic87dd year; save ./temp/shock-stimulus-temp, replace;
erase ./temp/sh-tr-upstream.dta; erase ./temp/sic87-year-grid-temp2b.dta;

*** Unite pieces together;
use ./temp/shock-baselines-temp, clear;
for any `SHOCK': ren DX DOX; renpfix DOlnb Dlnb;
sort sic87dd year; merge sic87dd year using ./temp/shock-stimulus-temp; assert _m==3; drop _m;
tsset sic87dd year; 
for var D*: gen X_l0=X \ gen X_l1=l1.X \ gen X_l2=l2.X \ gen X_l3=l3.X; 
for var Z* G*: gen DX_l0=X \ gen DX_l1=l1.X \ gen DX_l2=l2.X \ gen DX_l3=l3.X; 
gen sic3=int(sic87dd/10); gen sic2=int(sic3/10); gen clstr=sic87dd;

*** Prepare weights and traded category (only used for annual program);
gen wt1=1;
egen temp0=min(year);
gen temp1=ln(nber_vadd) if year==temp0; egen wt2=mean(temp1), by(sic87dd); drop temp1;
gen temp1=nber_emp if year==temp0; egen wt3=mean(temp1), by(sic87dd); drop temp1; 
sort sic87dd; merge sic87dd using ./temp/sic87-hhi, keep(hhi) nok; tab _m; drop _m;
egen temp1=median(hhi); gen traded=(hhi>temp1); drop temp1 hhi;

*** Save prep file;
sort sic87dd year; xi i.year; compress; 
save ./temp/nw-macro2b`i', replace;
for any baselines stimulus: erase ./temp/shock-X-temp.dta;
};

************************************;
************************************;
*** ANALYSIS                     ***;
************************************;
************************************;

**************************************;
**************************************;
*** OLS Single-Shock Estimations   ***;
**************************************;
**************************************;

*** Core table OLS;
local SH esfed;
use if DO`SH'_l1!=. using ./temp/nw-macro2b1, clear; 
for any nber_rvadd nber_emp nber_rsales:
\ gen Tlag1=DlX_l1
\ qui areg DlX_l0 Tlag1 DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1 DZR4LD`SH'_l1 [aw=wt1], a(year) cl(clstr)
\ margins, dydx(Tlag1 DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1 )
\ qui areg DlX_l0 Tlag1 DZNLU`SH'_l1 DZNLD`SH'_l1 DZDLU`SH'_l1 DZR4LD`SH'_l1 [aw=wt1], a(year) cl(clstr)
\ margins, dydx(Tlag1 DZNLU`SH'_l1 DZNLD`SH'_l1 DZDLU`SH'_l1)
\ test DZNLD`SH'_l1=DZDLU`SH'_l1
\ drop Tlag*;

*** Core table IV;
local SH l_import_usch;
local IV l_import_otch;
use if DO`SH'_l1!=. using ./temp/nw-macro2b1, clear; 
for any nber_rvadd nber_emp nber_rsales:
\ gen Tlag1=DlX_l1
\ qui ivregress 2sls DlX_l0 Tlag1 (DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1 DZR4LD`SH'_l1=DZTLU`IV'_l1 DZTLD`IV'_l1 DO`IV'_l1 DZR4LD`IV'_l1) _I* [aw=wt1], cl(clstr)
\ margins, dydx(Tlag1 DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1)
\ qui ivregress 2sls DlX_l0 Tlag1 (DZNLU`SH'_l1 DZNLD`SH'_l1 DZDLU`SH'_l1 DZR4LD`SH'_l1=DZNLU`IV'_l1 DZNLD`IV'_l1 DZDLU`IV'_l1 DZR4LD`IV'_l1) _I* [aw=wt1], vce(cl clstr)
\ margins, dydx(Tlag1 DZNLU`SH'_l1 DZNLD`SH'_l1 DZDLU`SH'_l1)
\ test DZNLD`SH'_l1=DZDLU`SH'_l1
\ drop Tlag*;

*** End of program;
log close;
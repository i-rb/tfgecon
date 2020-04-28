#delimit;
cap n log close; 
cd /export/projects/wkerr_ethnicity_project/networks/macro/replication;
log using nw-macro-2a.log, replace; 

* William Kerr, TGG;
* Core Analysis of Interconnections;
* stata-mp8-10g -b do nw-macro-2a.do;
* Last Modified: May 2015;

clear all; set matsize 5000; set more off;

local znber nber_emp nber_vadd nber_rvadd nber_sales nber_rsales nber_lprod nber_rlprod;
local znber2 nber_emp* nber_vadd* nber_rvadd* nber_sales* nber_rsales* nber_lprod* nber_rlprod*;
local znber3 *nber_emp *nber_vadd *nber_rvadd *nber_sales *nber_rsales *nber_lprod *nber_rlprod;
local znberT nber_rvadd nber_emp nber_rlprod nber_rsales nber_sales;
local trade l_import_usch l_import_otch;
local SHOCK zlnber_rvadd zlnber_sales zlnber_rsales zlnber_emp lnber_rvadd lnber_emp lnber_rlprod l_import_usch l_import_otch esfed ltfp4 ltfp5 lfmct lfuct;
local GEO GAD;
local LB 0.1;
local UB 99.9;
local SH l_import_otch;

**************************;
**************************;
*** Prepare Shocks      **;
**************************;
**************************;

*** Defense spending shock entry;
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
for var sp*:
\ gen temp1=X if year==1991 \ egen temp2=min(temp1)
\ replace X=ln(X/temp2) \ drop temp*;
keep year sp*; sort year; save ./temp/fed-spend, replace;
use ./raw/all_sales, clear;
gen gshfed=(def_sales+nondef_sales)/tot_sales;
for var gsh*: replace X=0 if X==. | X<0;
keep sic87dd gsh*; sum, d; cross using ./temp/fed-spend;
for any fed: gen esX=gshX*spX; 
keep sic87dd year es*;
sort sic87dd year; save ./temp/federal-merge, replace;

*** Prepare patent merge file;
use sic87dd_up year using ./temp/sic87-year-grid-full, clear; duplicates drop;
ren sic87dd sic4;
sort sic4 year; merge sic4 year using ./raw/cite-us-trend2b; renpfix f u; tab _m; drop _m;
sort sic4 year; merge sic4 year using ./raw/cite-for-trend2b; tab _m; drop _m;
keep sic4 year fmct fuct umct uuct; 
for any fmct fuct umct uuct: gen lX=ln(X);
sort sic4 year; save ./temp/patent-merge, replace;

*** Prepare NBER inputs;
use ./temp/nber-inputs, clear;
ren nber_nom_vadd nber_vadd; ren nber_nom_vship nber_sales;
for var nber_emp nber_vadd nber_sales: gen lX=ln(X);
gen lnber_rvadd=ln(nber_vadd/nber_piship); gen lnber_rsales=ln(nber_sales/nber_piship); 
gen lnber_lprod=lnber_vadd-lnber_emp; gen lnber_rlprod=lnber_rvadd-lnber_emp; 

*** Unite pieces together;
ren sic87dd sic; sort sic year; merge sic year using ./raw/nber-sic5809, nok keep(tfp*); tab _m; drop _m; for var tfp*: gen lX=ln(X); ren sic sic4;
sort sic4 year; merge sic4 year using ./temp/patent-merge, nok keep(lf*); erase ./temp/patent-merge.dta; tab _m; drop _m; ren sic4 sic87dd;
sort sic87dd year; merge sic87dd year using ./raw/AF_trade_variables, nok keep(`trade'); assert _m==3; drop _m; for var l_*: replace X=-X;
sort sic87dd year; merge sic87dd year using ./temp/federal-merge, nok; erase ./temp/federal-merge.dta; assert _m==3; drop _m;

*** Save shocks baseline;
keep sic87dd year nber_emp nber_vadd lnber_* l_import_usch l_import_otch esfed ltfp4 ltfp5 lfmct lfuct;
sort sic87dd year; compress; save ./temp/shock-baselines, replace; sum;

forvalues i=1(1)5 {;

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
sort sic87dd year; save ./temp/shock-baselines-temp, replace; sum;

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
sort sic87dd_up sic87dd_down; merge sic87dd_up sic87dd_down using ./temp/combined-networks, nok; keep if _m==3; drop _m;
for var geo12 geo123: replace X=. if sic87dd_up==sic87dd_down;
sort sic87dd_up sic87dd_down; save ./temp/sic87-year-grid-temp2a, replace;

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
use ./temp/sic87-year-grid-temp2a, clear;
for any `SHOCK': 
\ gen ZTFDX=DDX*io_perc_up
\ gen ZTLDX=DDX*io_Lperc_up
\ gen ZDLDX=DDX*(1+io_Lperc_up) if sic87dd_up==sic87dd_down
\ gen ZNLDX=DDX*io_Lperc_up if sic87dd_up!=sic87dd_down
\ gen GADX=DDX*geo12
\ gen GHDX=DDX*geo123;
collapse (sum) Z* G*, by(sic87dd_up year) fast; ren sic87dd sic87dd;
sort sic87dd year; merge sic87dd year using ./temp/sh-tr-upstream; assert _m==3; drop _m;
sort sic87dd year; save ./temp/shock-stimulus-temp, replace;
erase ./temp/sh-tr-upstream.dta; erase ./temp/sic87-year-grid-temp2a.dta;

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
save ./temp/nw-macro2a`i', replace;
for any baselines stimulus: erase ./temp/shock-X-temp.dta;
};

************************************;
************************************;
*** ANALYSIS                     ***;
************************************;
************************************;

*****************************;
*** Correlation Tables      **;
*****************************;

*** Network elements;
use ./temp/combined-networks, replace; sum;
su io_Lperc_up io_perc_up io_Lperc_down io_perc_down geo12 geo123;
pwcorr io_Lperc_up io_perc_up io_Lperc_down io_perc_down geo12 geo123;

*** Shock correlation elements;
use if DOl_import_otch_l1!=. & Dlnber_rvadd!=. & Dlnber_rvadd_l1!=. using ./temp/nw-macro2a1, clear; 
for var DOl_import_otch_l1 DOesfed_l1 DOltfp4_l1 DOlfuct_l1: qui areg X, a(year) \ predict RX, residual;
pwcorr RDOl_import_otch_l1 RDOesfed_l1 RDOltfp4_l1 RDOlfuct_l1, star(0.01); 

**************************************;
**************************************;
*** OLS Single-Shock Estimations   ***;
**************************************;
**************************************;

foreach SH in esfed ltfp4 lfuct {; 

if "`SH'" == "l_import_otch" {;
		local SH2 TR;
		local ztest DZTLD`SH'_l1;
		local ztest2 DZNLD`SH'_l1;
	};
	else if "`SH'" == "l_import_usch" {;
		local SH2 OTR;
		local ztest DZTLD`SH'_l1;
		local ztest2 DZNLD`SH'_l1;
	};
	else if "`SH'" == "esfed" {;
		local SH2 FED;
		local ztest DZTLD`SH'_l1;
		local ztest2 DZNLD`SH'_l1;
	};
	else if "`SH'" == "ltfp4" {;
		local SH2 TFP;
		local ztest DZTLU`SH'_l1;
		local ztest2 DZNLU`SH'_l1;
	};
	else if "`SH'" == "lfuct" {;
		local SH2 PAT;
		local ztest DZTLU`SH'_l1;
		local ztest2 DZNLU`SH'_l1;
	};

*** Core table;
use if DO`SH'_l1!=. using ./temp/nw-macro2a1, clear; 
eststo clear;
for any `znberT':
\ gen Tlag1=DlX_l1
\ gen Tlag2=DlX_l2
\ gen Tlag3=DlX_l3
\ qui eststo: areg DlX_l0 Tlag1 DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1 [aw=wt1], a(year) cl(clstr)
  \ qui test `ztest'=DO`SH'_l1 \ qui estadd r(p)
\ qui eststo: areg DlX_l0 Tlag1 Tlag2 Tlag3 DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1 [aw=wt1], a(year) cl(clstr)
  \ qui test `ztest'=DO`SH'_l1 \ qui estadd r(p)
\ drop Tlag*;
tempfile specs;
esttab * using "`specs'.csv",
	b(%9.3f) se(%9.3f)
	o(Tlag1 Tlag2 Tlag3 DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1)
	k(Tlag1 Tlag2 Tlag3 DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1)
	star(* .10 ** .05 *** .01) nonotes label
	stats(N p, fmt(%4.0f %9.3f %9.3f %9.3f))
	replace;
insheet using "`specs'.csv", comma clear;
export excel "nw-macro.xlsx", sheetreplace sheet(`SH2'1);

*** Core table -- Theoretically Precise;
use if DO`SH'_l1!=. using ./temp/nw-macro2a1, clear; 
eststo clear;
for any `znberT':
\ gen Tlag1=DlX_l1
\ gen Tlag2=DlX_l2
\ gen Tlag3=DlX_l3
\ pwcorr DZNLU`SH'_l1 DZDLU`SH'_l1 DZNLD`SH'_l1 DZDLD`SH'_l1
\ qui eststo: areg DlX_l0 Tlag1 DZNLU`SH'_l1 DZNLD`SH'_l1 DZDLU`SH'_l1 [aw=wt1], a(year) cl(clstr)
  \ qui test `ztest2'=DZDLU`SH'_l1 \ qui estadd r(p)
\ qui eststo: areg DlX_l0 Tlag1 Tlag2 Tlag3 DZNLU`SH'_l1 DZNLD`SH'_l1 DZDLU`SH'_l1 [aw=wt1], a(year) cl(clstr)
  \ qui test `ztest2'=DZDLU`SH'_l1 \ qui estadd r(p)
\ drop Tlag*;
tempfile specs;
esttab * using "`specs'.csv",
	b(%9.3f) se(%9.3f)
	o(Tlag1 Tlag2 Tlag3 DZNLU`SH'_l1 DZNLD`SH'_l1 DZDLU`SH'_l1)
	k(Tlag1 Tlag2 Tlag3 DZNLU`SH'_l1 DZNLD`SH'_l1 DZDLU`SH'_l1)
	star(* .10 ** .05 *** .01) nonotes label
	stats(N p, fmt(%4.0f %9.3f %9.3f %9.3f))
	replace;
insheet using "`specs'.csv", comma clear;
export excel "nw-macro.xlsx", sheetreplace sheet(`SH2'1b);

*** Core table with extra lags;
use if DZTLU`SH'_l1!=. using ./temp/nw-macro2a1, clear; 
eststo clear;
for any `znberT':
\ gen Tlag1=DlX_l1
\ gen Tlag2=DlX_l2
\ gen Tlag3=DlX_l3
\ qui eststo: areg DlX_l0 Tlag1 Tlag2 Tlag3 DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1 [aw=wt1], a(year) cl(clstr)
\ qui eststo: areg DlX_l0 Tlag1 Tlag2 Tlag3 DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1 DO`SH'_l2 DO`SH'_l3 [aw=wt1], a(year) cl(clstr)
\ qui eststo: areg DlX_l0 Tlag1 Tlag2 Tlag3 DZTLU`SH'_l1 DZTLU`SH'_l2 DZTLU`SH'_l3 DZTLD`SH'_l1 DZTLD`SH'_l2 DZTLD`SH'_l3 DO`SH'_l1 [aw=wt1], a(year) cl(clstr)
\ qui eststo: areg DlX_l0 Tlag1 Tlag2 Tlag3 DZTLU`SH'_l1 DZTLU`SH'_l2 DZTLU`SH'_l3 DZTLD`SH'_l1 DZTLD`SH'_l2 DZTLD`SH'_l3 DO`SH'_l1 DO`SH'_l2 DO`SH'_l3 [aw=wt1], a(year) cl(clstr)
\ drop Tlag*;
tempfile specs;
esttab * using "`specs'.csv",
	b(%9.3f) se(%9.3f)
	o(Tlag1 Tlag2 Tlag3 DZTLU`SH'_l1 DZTLU`SH'_l2 DZTLU`SH'_l3 DZTLD`SH'_l1 DZTLD`SH'_l2 DZTLD`SH'_l3 DO`SH'_l1 DO`SH'_l2 DO`SH'_l3)
	k(Tlag1 Tlag2 Tlag3 DZTLU`SH'_l1 DZTLU`SH'_l2 DZTLU`SH'_l3 DZTLD`SH'_l1 DZTLD`SH'_l2 DZTLD`SH'_l3 DO`SH'_l1 DO`SH'_l2 DO`SH'_l3)
	nostar nonotes label
	stats(N, fmt(%4.0f %9.3f %9.3f %9.3f))
	replace;
insheet using "`specs'.csv", comma clear;
export excel "nw-macro.xlsx", sheetreplace sheet(`SH2'1c);

*** Robustness table;
for any `znberT':
\ use if DO`SH'_l1!=. using ./temp/nw-macro2a1, clear 
\ eststo clear
\ qui eststo: areg DlX_l0 DlX_l1 DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1 [aw=wt1], a(year) cl(clstr)
  \ qui test `ztest'=DO`SH'_l1 \ qui estadd r(p)
\ qui eststo: areg DlX_l0 DlX_l1 DZTLU`SH'_l1 DZTLD`SH'_l1 [aw=wt1], a(year) cl(clstr)
  \ qui test `ztest'=1e5 \ qui estadd r(p)
\ qui eststo: areg DlX_l0 DlX_l1 DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1 [aw=wt2], a(year) cl(clstr)
  \ qui test `ztest'=DO`SH'_l1 \ qui estadd r(p)
\ qui eststo: areg DlX_l0 DlX_l1 DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1 [aw=wt3], a(year) cl(clstr)
  \ qui test `ztest'=DO`SH'_l1 \ qui estadd r(p)
\ qui eststo: areg DlX_l0 DlX_l1 DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1 _I* [aw=wt1], a(sic2) cl(clstr)
  \ qui test `ztest'=DO`SH'_l1 \ qui estadd r(p)
\ qui eststo: areg DlX_l0 DlX_l1 DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1 _I* [aw=wt1], a(sic3) cl(clstr)
  \ qui test `ztest'=DO`SH'_l1 \ qui estadd r(p)
\ qui eststo: areg DlX_l0 DlX_l1 DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1 _I* [aw=wt1], a(sic87dd) cl(clstr)
  \ qui test `ztest'=DO`SH'_l1 \ qui estadd r(p)
\ tempfile specs
\ esttab * using "`specs'.csv",
	b(%9.3f) se(%9.3f)
	o(DlX_l1 DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1)
	k(DlX_l1 DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1)
	star(* .10 ** .05 *** .01) nonotes label
	stats(N p, fmt(%4.0f %9.3f %9.3f %9.3f))
	replace
\ insheet using "`specs'.csv", comma clear
\ export excel "nw-macro.xlsx", sheetreplace sheet(`SH2'2-X);

*** Robustness table -- Theoretically Precise;
for any `znberT':
\ use if DO`SH'_l1!=. using ./temp/nw-macro2a1, clear 
\ eststo clear
\ qui eststo: areg DlX_l0 DlX_l1 DZNLU`SH'_l1 DZNLD`SH'_l1 DZDLU`SH'_l1 [aw=wt1], a(year) cl(clstr)
  \ qui test `ztest2'=DZDLU`SH'_l1 \ qui estadd r(p)
\ qui eststo: areg DlX_l0 DlX_l1 DZNLU`SH'_l1 DZNLD`SH'_l1 [aw=wt1], a(year) cl(clstr)
  \ qui test `ztest2'=1e5 \ qui estadd r(p)
\ qui eststo: areg DlX_l0 DlX_l1 DZNLU`SH'_l1 DZNLD`SH'_l1 DZDLU`SH'_l1 [aw=wt2], a(year) cl(clstr)
  \ qui test `ztest2'=DZDLU`SH'_l1 \ qui estadd r(p)
\ qui eststo: areg DlX_l0 DlX_l1 DZNLU`SH'_l1 DZNLD`SH'_l1 DZDLU`SH'_l1 [aw=wt3], a(year) cl(clstr)
  \ qui test `ztest2'=DZDLU`SH'_l1 \ qui estadd r(p)
\ qui eststo: areg DlX_l0 DlX_l1 DZNLU`SH'_l1 DZNLD`SH'_l1 DZDLU`SH'_l1 _I* [aw=wt1], a(sic2) cl(clstr)
  \ qui test `ztest2'=DZDLU`SH'_l1 \ qui estadd r(p)
\ qui eststo: areg DlX_l0 DlX_l1 DZNLU`SH'_l1 DZNLD`SH'_l1 DZDLU`SH'_l1 _I* [aw=wt1], a(sic3) cl(clstr)
  \ qui test `ztest2'=DZDLU`SH'_l1 \ qui estadd r(p)
\ qui eststo: areg DlX_l0 DlX_l1 DZNLU`SH'_l1 DZNLD`SH'_l1 DZDLU`SH'_l1 _I* [aw=wt1], a(sic87dd) cl(clstr)
  \ qui test `ztest2'=DZDLU`SH'_l1 \ qui estadd r(p)
\ tempfile specs
\ esttab * using "`specs'.csv",
	b(%9.3f) se(%9.3f)
	o(DlX_l1 DZNLU`SH'_l1 DZNLD`SH'_l1 DZDLU`SH'_l1)
	k(DlX_l1 DZNLU`SH'_l1 DZNLD`SH'_l1 DZDLU`SH'_l1)
	star(* .10 ** .05 *** .01) nonotes label
	stats(N p, fmt(%4.0f %9.3f %9.3f %9.3f))
	replace
\ insheet using "`specs'.csv", comma clear
\ export excel "nw-macro.xlsx", sheetreplace sheet(`SH2'2b-X);

*** Lag table;
for any `znberT':
\ eststo clear
\ use if DO`SH'_l1!=. using ./temp/nw-macro2a1, clear 
\ qui eststo: areg DlX_l0 DlX_l1 DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1 [aw=wt1], a(year) cl(clstr)
  \ qui test `ztest'=DO`SH'_l1 \ qui estadd r(p)
\ use ./temp/nw-macro2a2, clear 
\ qui eststo: areg DlX_l0 DlX_l1 DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1 [aw=wt1], a(year) cl(clstr)
  \ qui test `ztest'=DO`SH'_l1 \ qui estadd r(p)
\ use ./temp/nw-macro2a3, clear 
\ qui eststo: areg DlX_l0 DlX_l1 DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1 [aw=wt1], a(year) cl(clstr)
  \ qui test `ztest'=DO`SH'_l1 \ qui estadd r(p)
\ use ./temp/nw-macro2a4, clear 
\ qui eststo: areg DlX_l0 DlX_l1 DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1 [aw=wt1], a(year) cl(clstr)
  \ qui test `ztest'=DO`SH'_l1 \ qui estadd r(p)
\ use ./temp/nw-macro2a5, clear 
\ qui eststo: areg DlX_l0 DlX_l1 DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1 [aw=wt1], a(year) cl(clstr)
  \ qui test `ztest'=DO`SH'_l1 \ qui estadd r(p)
\ tempfile specs
\ esttab * using "`specs'.csv",
	b(%9.3f) se(%9.3f)
	o(DlX_l1 DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1)
	k(DlX_l1 DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1)
	star(* .10 ** .05 *** .01) nonotes label
	stats(N p, fmt(%4.0f %9.3f %9.3f %9.3f))
	replace
\ insheet using "`specs'.csv", comma clear
\ export excel "nw-macro.xlsx", sheetreplace sheet(`SH2'3-X);

*** Lag table -- Theoretically Precise;
for any `znberT':
\ eststo clear
\ use if DO`SH'_l1!=. using ./temp/nw-macro2a1, clear 
\ qui eststo: areg DlX_l0 DlX_l1 DZNLU`SH'_l1 DZNLD`SH'_l1 DZDLU`SH'_l1 [aw=wt1], a(year) cl(clstr)
  \ qui test `ztest2'=DZDLU`SH'_l1 \ qui estadd r(p)
\ use ./temp/nw-macro2a2, clear 
\ qui eststo: areg DlX_l0 DlX_l1 DZNLU`SH'_l1 DZNLD`SH'_l1 DZDLU`SH'_l1 [aw=wt1], a(year) cl(clstr)
  \ qui test `ztest2'=DZDLU`SH'_l1 \ qui estadd r(p)
\ use ./temp/nw-macro2a3, clear 
\ qui eststo: areg DlX_l0 DlX_l1 DZNLU`SH'_l1 DZNLD`SH'_l1 DZDLU`SH'_l1 [aw=wt1], a(year) cl(clstr)
  \ qui test `ztest2'=DZDLU`SH'_l1 \ qui estadd r(p)
\ use ./temp/nw-macro2a4, clear 
\ qui eststo: areg DlX_l0 DlX_l1 DZNLU`SH'_l1 DZNLD`SH'_l1 DZDLU`SH'_l1 [aw=wt1], a(year) cl(clstr)
  \ qui test `ztest2'=DZDLU`SH'_l1 \ qui estadd r(p)
\ use ./temp/nw-macro2a5, clear 
\ qui eststo: areg DlX_l0 DlX_l1 DZNLU`SH'_l1 DZNLD`SH'_l1 DZDLU`SH'_l1 [aw=wt1], a(year) cl(clstr)
  \ qui test `ztest2'=DZDLU`SH'_l1 \ qui estadd r(p)
\ tempfile specs
\ esttab * using "`specs'.csv",
	b(%9.3f) se(%9.3f)
	o(DlX_l1 DZNLU`SH'_l1 DZNLD`SH'_l1 DZDLU`SH'_l1)
	k(DlX_l1 DZNLU`SH'_l1 DZNLD`SH'_l1 DZDLU`SH'_l1)
	star(* .10 ** .05 *** .01) nonotes label
	stats(N p, fmt(%4.0f %9.3f %9.3f %9.3f))
	replace
\ insheet using "`specs'.csv", comma clear
\ export excel "nw-macro.xlsx", sheetreplace sheet(`SH2'3b-X);

*** Comparison of sales-vadd variants;
use if DO`SH'_l1!=. using ./temp/nw-macro2a1, clear;
eststo clear; 
for any nber_rvadd nber_vadd nber_rsales nber_sales:
\ gen Tlag1=DlX_l1
\ qui eststo: areg DlX_l0 Tlag1 DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1 [aw=wt1], a(year) cl(clstr)
\ drop Tlag*;
tempfile specs;
esttab * using "`specs'.csv",
	b(%9.3f) se(%9.3f)
	o(Tlag1 DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1)
	k(Tlag1 DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1)
	star(* .10 ** .05 *** .01) nonotes label
	stats(N, fmt(%4.0f %9.3f %9.3f %9.3f))
	replace;
insheet using "`specs'.csv", comma clear;
export excel "nw-macro.xlsx", sheetreplace sheet(`SH2'4);

*** Psi estimates table;
use if DO`SH'_l1!=. using ./temp/nw-macro2a1, clear; 
eststo clear;
for any `znberT':
\ gen Tlag1=DlX_l1
\ qui eststo: areg DlX_l0 Tlag1 DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1 [aw=wt1], a(year) cl(clstr)
\ gen DVtemp=DlX_l0-0.0*Tlag1
\ qui eststo: areg DVtemp DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1 [aw=wt1], a(year) cl(clstr)
\ replace DVtemp=DlX_l0-0.1*Tlag1
\ qui eststo: areg DVtemp DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1 [aw=wt1], a(year) cl(clstr)
\ replace DVtemp=DlX_l0-0.2*Tlag1
\ qui eststo: areg DVtemp DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1 [aw=wt1], a(year) cl(clstr)
\ replace DVtemp=DlX_l0-0.3*Tlag1
\ qui eststo: areg DVtemp DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1 [aw=wt1], a(year) cl(clstr)
\ replace DVtemp=DlX_l0-0.4*Tlag1
\ qui eststo: areg DVtemp DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1 [aw=wt1], a(year) cl(clstr)
\ replace DVtemp=DlX_l0-0.5*Tlag1
\ qui eststo: areg DVtemp DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1 [aw=wt1], a(year) cl(clstr)
\ replace DVtemp=DlX_l0-0.6*Tlag1
\ qui eststo: areg DVtemp DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1 [aw=wt1], a(year) cl(clstr)
\ replace DVtemp=DlX_l0-0.7*Tlag1
\ qui eststo: areg DVtemp DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1 [aw=wt1], a(year) cl(clstr)
\ replace DVtemp=DlX_l0-0.8*Tlag1
\ qui eststo: areg DVtemp DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1 [aw=wt1], a(year) cl(clstr)
\ replace DVtemp=DlX_l0-0.9*Tlag1
\ qui eststo: areg DVtemp DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1 [aw=wt1], a(year) cl(clstr)
\ replace DVtemp=DlX_l0-1.0*Tlag1
\ qui eststo: areg DVtemp DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1 [aw=wt1], a(year) cl(clstr)
\ drop DVtemp Tlag*;
tempfile specs;
esttab * using "`specs'.csv",
	b(%9.3f) se(%9.3f)
	o(Tlag1 DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1)
	k(Tlag1 DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1)
	star(* .10 ** .05 *** .01) nonotes label
	stats(N, fmt(%4.0f %9.3f %9.3f %9.3f))
	replace;
insheet using "`specs'.csv", comma clear;
export excel "nw-macro.xlsx", sheetreplace sheet(`SH2'5);

};

*** Variable table with extra lags for appendix summation;
use ./temp/nw-macro2a1, clear; 
foreach SH in esfed ltfp4 lfuct {; 
for any `znberT':
\ gen Tlag1=DlX_l1
\ gen Tlag2=DlX_l2
\ gen Tlag3=DlX_l3
\ qui areg DlX_l0 Tlag1 Tlag2 Tlag3 DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1 [aw=wt1], a(year) cl(clstr)
\ lincom DZTLU`SH'_l1 
\ lincom DZTLD`SH'_l1 
\ lincom DO`SH'_l1 
\ qui areg DlX_l0 Tlag1 Tlag2 Tlag3 DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1 DO`SH'_l2 DO`SH'_l3 [aw=wt1], a(year) cl(clstr)
\ lincom DZTLU`SH'_l1 
\ lincom DZTLD`SH'_l1 
\ lincom DO`SH'_l1+DO`SH'_l2+DO`SH'_l3  
\ qui areg DlX_l0 Tlag1 Tlag2 Tlag3 DZTLU`SH'_l1 DZTLU`SH'_l2 DZTLU`SH'_l3 DZTLD`SH'_l1 DZTLD`SH'_l2 DZTLD`SH'_l3 DO`SH'_l1 [aw=wt1], a(year) cl(clstr)
\ lincom DZTLU`SH'_l1+DZTLU`SH'_l2+DZTLU`SH'_l3  
\ lincom DZTLD`SH'_l1+DZTLD`SH'_l2+DZTLD`SH'_l3 
\ lincom DO`SH'_l1 
\ qui areg DlX_l0 Tlag1 Tlag2 Tlag3 DZTLU`SH'_l1 DZTLU`SH'_l2 DZTLU`SH'_l3 DZTLD`SH'_l1 DZTLD`SH'_l2 DZTLD`SH'_l3 DO`SH'_l1 DO`SH'_l2 DO`SH'_l3 [aw=wt1], a(year) cl(clstr)
\ lincom DZTLU`SH'_l1+DZTLU`SH'_l2+DZTLU`SH'_l3  
\ lincom DZTLD`SH'_l1+DZTLD`SH'_l2+DZTLD`SH'_l3
\ lincom DO`SH'_l1+DO`SH'_l2+DO`SH'_l3
\ drop Tlag*;
};

**********************************;
**********************************;
*** VAR Estimations            ***;
**********************************;
**********************************;

local SH l_import_usch;
local IV l_import_otch;

*** Real value added;
use ./temp/nw-macro2a1, clear;
xi i.year;
eststo clear;
gen Tlag1=Dlnber_rvadd_l1;
local SH l_import_usch;
local IV l_import_otch;
gen own=DO`SH'_l1;
qui eststo: ivregress 2sls Dlnber_rvadd_l0 Tlag1 (DZTLDzlnber_rvadd_l1 own = DZTLD`IV'_l1 DZTLD`IV'_l2 DO`IV'_l1 DO`IV'_l2) _I*, vce(cl clstr);
estat firststage;
qui eststo: ivregress 2sls Dlnber_rvadd_l0 Tlag1 (DZTLUzlnber_rvadd_l1 DZTLDzlnber_rvadd_l1 own = DZTLU`IV'_l1 DZTLU`IV'_l2 DZTLD`IV'_l1 DZTLD`IV'_l2 DO`IV'_l1 DO`IV'_l2) _I*, vce(cl clstr);
estat firststage;
local SH esfed;
replace own=DO`SH'_l1;
qui eststo: ivregress 2sls Dlnber_rvadd_l0 Tlag1 (DZTLDzlnber_rvadd_l1 = DZTLD`SH'_l1 DZTLD`SH'_l2) own _I*, vce(cl clstr);
estat firststage;
qui eststo: ivregress 2sls Dlnber_rvadd_l0 Tlag1 (DZTLUzlnber_rvadd_l1 DZTLDzlnber_rvadd_l1 = DZTLU`SH'_l1 DZTLU`SH'_l2 DZTLD`SH'_l1 DZTLD`SH'_l2) own _I*, vce(cl clstr);
estat firststage;
local SH ltfp4;
replace own=DO`SH'_l1;
qui eststo: ivregress 2sls Dlnber_rvadd_l0 Tlag1 (DZTLUzlnber_rvadd_l1 = DZTLU`SH'_l1 DZTLU`SH'_l2) own _I*, vce(cl clstr);
estat firststage;
qui eststo: ivregress 2sls Dlnber_rvadd_l0 Tlag1 (DZTLUzlnber_rvadd_l1 DZTLDzlnber_rvadd_l1 = DZTLU`SH'_l1 DZTLU`SH'_l2 DZTLD`SH'_l1 DZTLD`SH'_l2) own _I*, vce(cl clstr); 
estat firststage;
local SH lfuct;
replace own=DO`SH'_l1;
qui eststo: ivregress 2sls Dlnber_rvadd_l0 Tlag1 (DZTLUzlnber_rvadd_l1 = DZTLU`SH'_l1 DZTLU`SH'_l2) own _I*, vce(cl clstr);
estat firststage;
qui eststo: ivregress 2sls Dlnber_rvadd_l0 Tlag1 (DZTLUzlnber_rvadd_l1 DZTLDzlnber_rvadd_l1 = DZTLU`SH'_l1 DZTLU`SH'_l2 DZTLD`SH'_l1 DZTLD`SH'_l2) own _I*, vce(cl clstr);
estat firststage;
drop Tlag* own;
tempfile specs;
esttab * using "`specs'.csv",
	b(%9.3f) se(%9.3f)
	o(Tlag1 DZTLUzlnber_rvadd_l1 DZTLDzlnber_rvadd_l1 own)
	k(Tlag1 DZTLUzlnber_rvadd_l1 DZTLDzlnber_rvadd_l1 own)
	star(* .10 ** .05 *** .01) nonotes label
	stats(N, fmt(%4.0f %9.3f %9.3f %9.3f))
	replace;
insheet using "`specs'.csv", comma clear;
export excel "nw-macro.xlsx", sheetreplace sheet(VAR-nber_rvadd1);

use ./temp/nw-macro2a1, clear;
xi i.year;
eststo clear;
gen Tlag1=Dlnber_rvadd_l1;
gen Tlag2=Dlnber_rvadd_l2;
gen Tlag3=Dlnber_rvadd_l3;
local SH l_import_usch;
local IV l_import_otch;
gen own=DO`SH'_l1;
qui eststo: ivregress 2sls Dlnber_rvadd_l0 Tlag1 Tlag2 Tlag3 (DZTLDzlnber_rvadd_l1 own = DZTLD`IV'_l1 DZTLD`IV'_l2 DO`IV'_l1 DO`IV'_l2) _I*, vce(cl clstr);
qui eststo: ivregress 2sls Dlnber_rvadd_l0 Tlag1 Tlag2 Tlag3 (DZTLUzlnber_rvadd_l1 DZTLDzlnber_rvadd_l1 own = DZTLU`IV'_l1 DZTLU`IV'_l2 DZTLD`IV'_l1 DZTLD`IV'_l2 DO`IV'_l1 DO`IV'_l2) _I*, vce(cl clstr);
local SH esfed;
replace own=DO`SH'_l1;
qui eststo: ivregress 2sls Dlnber_rvadd_l0 Tlag1 Tlag2 Tlag3 (DZTLDzlnber_rvadd_l1 = DZTLD`SH'_l1 DZTLD`SH'_l2) own _I*, vce(cl clstr);
qui eststo: ivregress 2sls Dlnber_rvadd_l0 Tlag1 Tlag2 Tlag3 (DZTLUzlnber_rvadd_l1 DZTLDzlnber_rvadd_l1 = DZTLU`SH'_l1 DZTLU`SH'_l2 DZTLD`SH'_l1 DZTLD`SH'_l2) own _I*, vce(cl clstr);
local SH ltfp4;
replace own=DO`SH'_l1;
qui eststo: ivregress 2sls Dlnber_rvadd_l0 Tlag1 Tlag2 Tlag3 (DZTLUzlnber_rvadd_l1 = DZTLU`SH'_l1 DZTLU`SH'_l2) own _I*, vce(cl clstr);
qui eststo: ivregress 2sls Dlnber_rvadd_l0 Tlag1 Tlag2 Tlag3 (DZTLUzlnber_rvadd_l1 DZTLDzlnber_rvadd_l1 = DZTLU`SH'_l1 DZTLU`SH'_l2 DZTLD`SH'_l1 DZTLD`SH'_l2) own _I*, vce(cl clstr); 
local SH lfuct;
replace own=DO`SH'_l1;
qui eststo: ivregress 2sls Dlnber_rvadd_l0 Tlag1 Tlag2 Tlag3 (DZTLUzlnber_rvadd_l1 = DZTLU`SH'_l1 DZTLU`SH'_l2) own _I*, vce(cl clstr);
qui eststo: ivregress 2sls Dlnber_rvadd_l0 Tlag1 Tlag2 Tlag3 (DZTLUzlnber_rvadd_l1 DZTLDzlnber_rvadd_l1 = DZTLU`SH'_l1 DZTLU`SH'_l2 DZTLD`SH'_l1 DZTLD`SH'_l2) own _I*, vce(cl clstr);
drop Tlag* own;
tempfile specs;
esttab * using "`specs'.csv",
	b(%9.3f) se(%9.3f)
	o(Tlag1 Tlag2 Tlag3 DZTLUzlnber_rvadd_l1 DZTLDzlnber_rvadd_l1 own)
	k(Tlag1 Tlag2 Tlag3 DZTLUzlnber_rvadd_l1 DZTLDzlnber_rvadd_l1 own)
	star(* .10 ** .05 *** .01) nonotes label
	stats(N, fmt(%4.0f %9.3f %9.3f %9.3f))
	replace;
insheet using "`specs'.csv", comma clear;
export excel "nw-macro.xlsx", sheetreplace sheet(VAR-nber_rvadd3);

*** Employment;
use ./temp/nw-macro2a1, clear;
xi i.year;
eststo clear;
gen Tlag1=Dlnber_emp_l1;
local SH l_import_usch;
local IV l_import_otch;
gen own=DO`SH'_l1;
qui eststo: ivregress 2sls Dlnber_emp_l0 Tlag1 (DZTLDzlnber_emp_l1 own = DZTLD`IV'_l1 DZTLD`IV'_l2 DO`IV'_l1 DO`IV'_l2) _I*, vce(cl clstr);
estat firststage;
qui eststo: ivregress 2sls Dlnber_emp_l0 Tlag1 (DZTLUzlnber_emp_l1 DZTLDzlnber_emp_l1 own = DZTLU`IV'_l1 DZTLU`IV'_l2 DZTLD`IV'_l1 DZTLD`IV'_l2 DO`IV'_l1 DO`IV'_l2) _I*, vce(cl clstr);
estat firststage;
local SH esfed;
replace own=DO`SH'_l1;
qui eststo: ivregress 2sls Dlnber_emp_l0 Tlag1 (DZTLDzlnber_emp_l1 = DZTLD`SH'_l1 DZTLD`SH'_l2) own _I*, vce(cl clstr);
estat firststage;
qui eststo: ivregress 2sls Dlnber_emp_l0 Tlag1 (DZTLUzlnber_emp_l1 DZTLDzlnber_emp_l1 = DZTLU`SH'_l1 DZTLU`SH'_l2 DZTLD`SH'_l1 DZTLD`SH'_l2) own _I*, vce(cl clstr);
estat firststage;
local SH ltfp4;
replace own=DO`SH'_l1;
qui eststo: ivregress 2sls Dlnber_emp_l0 Tlag1 (DZTLUzlnber_emp_l1 = DZTLU`SH'_l1 DZTLU`SH'_l2) own _I*, vce(cl clstr);
estat firststage;
qui eststo: ivregress 2sls Dlnber_emp_l0 Tlag1 (DZTLUzlnber_emp_l1 DZTLDzlnber_emp_l1 = DZTLU`SH'_l1 DZTLU`SH'_l2 DZTLD`SH'_l1 DZTLD`SH'_l2) own _I*, vce(cl clstr); 
estat firststage;
local SH lfuct;
replace own=DO`SH'_l1;
qui eststo: ivregress 2sls Dlnber_emp_l0 Tlag1 (DZTLUzlnber_emp_l1 = DZTLU`SH'_l1 DZTLU`SH'_l2) own _I*, vce(cl clstr);
estat firststage;
qui eststo: ivregress 2sls Dlnber_emp_l0 Tlag1 (DZTLUzlnber_emp_l1 DZTLDzlnber_emp_l1 = DZTLU`SH'_l1 DZTLU`SH'_l2 DZTLD`SH'_l1 DZTLD`SH'_l2) own _I*, vce(cl clstr);
estat firststage;
drop Tlag* own;
tempfile specs;
esttab * using "`specs'.csv",
	b(%9.3f) se(%9.3f)
	o(Tlag1 DZTLUzlnber_emp_l1 DZTLDzlnber_emp_l1 own)
	k(Tlag1 DZTLUzlnber_emp_l1 DZTLDzlnber_emp_l1 own)
	star(* .10 ** .05 *** .01) nonotes label
	stats(N, fmt(%4.0f %9.3f %9.3f %9.3f))
	replace;
insheet using "`specs'.csv", comma clear;
export excel "nw-macro.xlsx", sheetreplace sheet(VAR-nber_emp1);

use ./temp/nw-macro2a1, clear;
xi i.year;
eststo clear;
gen Tlag1=Dlnber_emp_l1;
gen Tlag2=Dlnber_emp_l2;
gen Tlag3=Dlnber_emp_l3;
local SH l_import_usch;
local IV l_import_otch;
gen own=DO`SH'_l1;
qui eststo: ivregress 2sls Dlnber_emp_l0 Tlag1 Tlag2 Tlag3 (DZTLDzlnber_emp_l1 own = DZTLD`IV'_l1 DZTLD`IV'_l2 DO`IV'_l1 DO`IV'_l2) _I*, vce(cl clstr);
qui eststo: ivregress 2sls Dlnber_emp_l0 Tlag1 Tlag2 Tlag3 (DZTLUzlnber_emp_l1 DZTLDzlnber_emp_l1 own = DZTLU`IV'_l1 DZTLU`IV'_l2 DZTLD`IV'_l1 DZTLD`IV'_l2 DO`IV'_l1 DO`IV'_l2) _I*, vce(cl clstr);
local SH esfed;
replace own=DO`SH'_l1;
qui eststo: ivregress 2sls Dlnber_emp_l0 Tlag1 Tlag2 Tlag3 (DZTLDzlnber_emp_l1 = DZTLD`SH'_l1 DZTLD`SH'_l2) own _I*, vce(cl clstr);
qui eststo: ivregress 2sls Dlnber_emp_l0 Tlag1 Tlag2 Tlag3 (DZTLUzlnber_emp_l1 DZTLDzlnber_emp_l1 = DZTLU`SH'_l1 DZTLU`SH'_l2 DZTLD`SH'_l1 DZTLD`SH'_l2) own _I*, vce(cl clstr);
local SH ltfp4;
replace own=DO`SH'_l1;
qui eststo: ivregress 2sls Dlnber_emp_l0 Tlag1 Tlag2 Tlag3 (DZTLUzlnber_emp_l1 = DZTLU`SH'_l1 DZTLU`SH'_l2) own _I*, vce(cl clstr);
qui eststo: ivregress 2sls Dlnber_emp_l0 Tlag1 Tlag2 Tlag3 (DZTLUzlnber_emp_l1 DZTLDzlnber_emp_l1 = DZTLU`SH'_l1 DZTLU`SH'_l2 DZTLD`SH'_l1 DZTLD`SH'_l2) own _I*, vce(cl clstr); 
local SH lfuct;
replace own=DO`SH'_l1;
qui eststo: ivregress 2sls Dlnber_emp_l0 Tlag1 Tlag2 Tlag3 (DZTLUzlnber_emp_l1 = DZTLU`SH'_l1 DZTLU`SH'_l2) own _I*, vce(cl clstr);
qui eststo: ivregress 2sls Dlnber_emp_l0 Tlag1 Tlag2 Tlag3 (DZTLUzlnber_emp_l1 DZTLDzlnber_emp_l1 = DZTLU`SH'_l1 DZTLU`SH'_l2 DZTLD`SH'_l1 DZTLD`SH'_l2) own _I*, vce(cl clstr);
drop Tlag* own;
tempfile specs;
esttab * using "`specs'.csv",
	b(%9.3f) se(%9.3f)
	o(Tlag1 Tlag2 Tlag3 DZTLUzlnber_emp_l1 DZTLDzlnber_emp_l1 own)
	k(Tlag1 Tlag2 Tlag3 DZTLUzlnber_emp_l1 DZTLDzlnber_emp_l1 own)
	star(* .10 ** .05 *** .01) nonotes label
	stats(N, fmt(%4.0f %9.3f %9.3f %9.3f))
	replace;
insheet using "`specs'.csv", comma clear;
export excel "nw-macro.xlsx", sheetreplace sheet(VAR-nber_emp3);

**********************************;
**********************************;
*** IV Estimations First Stage ***;
**********************************;
**********************************;

local SH l_import_usch;
local IV l_import_otch;
local ztest DZTLD`SH'_l1;
local ztest2 DZNLD`SH'_l1;

*** First Stage Documentation;
for any `znberT':
\ use if DO`SH'_l1!=. using ./temp/nw-macro2a1, clear 
\ gen Tlag1=DlX_l1
\ gen Tlag2=DlX_l2
\ gen Tlag3=DlX_l3
\ regress DlX_l0 Tlag1 DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1 _I* [aw=wt1], vce(cl clstr)
\ ivregress 2sls DlX_l0 Tlag1 (DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1=DZTLU`IV'_l1 DZTLD`IV'_l1 DO`IV'_l1) _I* [aw=wt1], vce(cl clstr) first
\ estat firststage
\ ivregress 2sls DlX_l0 Tlag1 Tlag2 Tlag3 (DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1=DZTLU`IV'_l1 DZTLD`IV'_l1 DO`IV'_l1) _I* [aw=wt1], vce(cl clstr) first
\ estat firststage
\ regress DlX_l0 Tlag1 DZNLU`SH'_l1 DZNLD`SH'_l1 DZDLU`SH'_l1 _I* [aw=wt1], vce(cl clstr)
\ test DZNLD`SH'_l1=DZDLU`SH'_l1
\ ivregress 2sls DlX_l0 Tlag1 (DZNLU`SH'_l1 DZNLD`SH'_l1 DZDLU`SH'_l1=DZNLU`IV'_l1 DZNLD`IV'_l1 DZDLU`IV'_l1) _I* [aw=wt1], vce(cl clstr) first
\ estat firststage
\ test DZNLD`SH'_l1=DZDLU`SH'_l1;

*************************************;
*************************************;
*** IV Single-Shock Estimations   ***;
*************************************;
*************************************;

*** Core table;
use if DO`SH'_l1!=. using ./temp/nw-macro2a1, clear; 
eststo clear;
for any `znberT':
\ gen Tlag1=DlX_l1
\ gen Tlag2=DlX_l2
\ gen Tlag3=DlX_l3
\ qui eststo: ivregress 2sls DlX_l0 Tlag1 (DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1=DZTLU`IV'_l1 DZTLD`IV'_l1 DO`IV'_l1) _I* [aw=wt1], cl(clstr)
  \ qui test `ztest'=DO`SH'_l1 \ qui estadd r(p)
\ qui eststo: ivregress 2sls DlX_l0 Tlag1 Tlag2 Tlag3 (DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1=DZTLU`IV'_l1 DZTLD`IV'_l1 DO`IV'_l1) _I* [aw=wt1], cl(clstr)
  \ qui test `ztest'=DO`SH'_l1 \ qui estadd r(p)
\ drop Tlag*;
tempfile specs;
esttab * using "`specs'.csv",
	b(%9.3f) se(%9.3f)
	o(Tlag1 Tlag2 Tlag3 DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1)
	k(Tlag1 Tlag2 Tlag3 DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1)
	star(* .10 ** .05 *** .01) nonotes label
	stats(N p, fmt(%4.0f %9.3f %9.3f %9.3f))
	replace;
insheet using "`specs'.csv", comma clear;
export excel "nw-macro.xlsx", sheetreplace sheet(IV1);

*** Core table -- Theoretically Precise;
use if DO`SH'_l1!=. using ./temp/nw-macro2a1, clear; 
eststo clear;
for any `znberT':
\ gen Tlag1=DlX_l1
\ gen Tlag2=DlX_l2
\ gen Tlag3=DlX_l3
\ qui eststo: ivregress 2sls DlX_l0 Tlag1 (DZNLU`SH'_l1 DZNLD`SH'_l1 DZDLU`SH'_l1=DZNLU`IV'_l1 DZNLD`IV'_l1 DZDLU`IV'_l1) _I* [aw=wt1], vce(cl clstr)
  \ qui test `ztest2'=DZDLU`SH'_l1 \ qui estadd r(p)
\ qui eststo: ivregress 2sls DlX_l0 Tlag1 Tlag2 Tlag3 (DZNLU`SH'_l1 DZNLD`SH'_l1 DZDLU`SH'_l1=DZNLU`IV'_l1 DZNLD`IV'_l1 DZDLU`IV'_l1) _I* [aw=wt1], vce(cl clstr)
  \ qui test `ztest2'=DZDLU`SH'_l1 \ qui estadd r(p)
\ drop Tlag*;
tempfile specs;
esttab * using "`specs'.csv",
	b(%9.3f) se(%9.3f)
	o(Tlag1 Tlag2 Tlag3 DZNLU`SH'_l1 DZNLD`SH'_l1 DZDLU`SH'_l1)
	k(Tlag1 Tlag2 Tlag3 DZNLU`SH'_l1 DZNLD`SH'_l1 DZDLU`SH'_l1)
	star(* .10 ** .05 *** .01) nonotes label
	stats(N p, fmt(%4.0f %9.3f %9.3f %9.3f))
	replace;
insheet using "`specs'.csv", comma clear;
export excel "nw-macro.xlsx", sheetreplace sheet(IV1b);

*** Core table with extra lags;
use if DZTLU`SH'_l1!=. using ./temp/nw-macro2a1, clear; 
eststo clear;
for any `znberT':
\ gen Tlag1=DlX_l1
\ gen Tlag2=DlX_l2
\ gen Tlag3=DlX_l3
\ qui eststo: ivregress 2sls DlX_l0 Tlag1 Tlag2 Tlag3 (DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1=DZTLU`IV'_l1 DZTLD`IV'_l1 DO`IV'_l1) _I* [aw=wt1], vce(cl clstr)
\ qui eststo: ivregress 2sls DlX_l0 Tlag1 Tlag2 Tlag3 (DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1 DO`SH'_l2 DO`SH'_l3=DZTLU`IV'_l1 DZTLD`IV'_l1 DO`IV'_l1 DO`IV'_l2 DO`IV'_l3) _I* [aw=wt1], vce(cl clstr)
\ qui eststo: ivregress 2sls DlX_l0 Tlag1 Tlag2 Tlag3 (DZTLU`SH'_l1 DZTLU`SH'_l2 DZTLU`SH'_l3 DZTLD`SH'_l1 DZTLD`SH'_l2 DZTLD`SH'_l3 DO`SH'_l1=DZTLU`IV'_l1 DZTLU`IV'_l2 DZTLU`IV'_l3 DZTLD`IV'_l1 DZTLD`IV'_l2 DZTLD`IV'_l3 DO`IV'_l1) _I* [aw=wt1], vce(cl clstr)
\ qui eststo: ivregress 2sls DlX_l0 Tlag1 Tlag2 Tlag3 (DZTLU`SH'_l1 DZTLU`SH'_l2 DZTLU`SH'_l3 DZTLD`SH'_l1 DZTLD`SH'_l2 DZTLD`SH'_l3 DO`SH'_l1 DO`SH'_l2 DO`SH'_l3=DZTLU`IV'_l1 DZTLU`IV'_l2 DZTLU`IV'_l3 DZTLD`IV'_l1 DZTLD`IV'_l2 DZTLD`IV'_l3 DO`IV'_l1 DO`IV'_l2 DO`IV'_l3) _I* [aw=wt1], vce(cl clstr)
\ drop Tlag*;
tempfile specs;
esttab * using "`specs'.csv",
	b(%9.3f) se(%9.3f)
	o(Tlag1 Tlag2 Tlag3 DZTLU`SH'_l1 DZTLU`SH'_l2 DZTLU`SH'_l3 DZTLD`SH'_l1 DZTLD`SH'_l2 DZTLD`SH'_l3 DO`SH'_l1 DO`SH'_l2 DO`SH'_l3)
	k(Tlag1 Tlag2 Tlag3 DZTLU`SH'_l1 DZTLU`SH'_l2 DZTLU`SH'_l3 DZTLD`SH'_l1 DZTLD`SH'_l2 DZTLD`SH'_l3 DO`SH'_l1 DO`SH'_l2 DO`SH'_l3)
	nostar nonotes label
	stats(N, fmt(%4.0f %9.3f %9.3f %9.3f))
	replace;
insheet using "`specs'.csv", comma clear;
export excel "nw-macro.xlsx", sheetreplace sheet(IV1c);

*** Robustness table;
for any `znberT':
\ use if DO`SH'_l1!=. using ./temp/nw-macro2a1, clear 
\ eststo clear
\ qui eststo: ivregress 2sls DlX_l0 DlX_l1 (DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1=DZTLU`IV'_l1 DZTLD`IV'_l1 DO`IV'_l1) _I* [aw=wt1], vce(cl clstr)
  \ qui test `ztest'=DO`SH'_l1 \ qui estadd r(p)
\ qui eststo: ivregress 2sls DlX_l0 DlX_l1 (DZTLU`SH'_l1 DZTLD`SH'_l1=DZTLU`IV'_l1 DZTLD`IV'_l1) _I* [aw=wt1], vce(cl clstr)
  \ qui test `ztest'=1e5 \ qui estadd r(p)
\ qui eststo: ivregress 2sls DlX_l0 DlX_l1 (DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1=DZTLU`IV'_l1 DZTLD`IV'_l1 DO`IV'_l1) _I* [aw=wt2], vce(cl clstr)
  \ qui test `ztest'=DO`SH'_l1 \ qui estadd r(p)
\ qui eststo: ivregress 2sls DlX_l0 DlX_l1 (DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1=DZTLU`IV'_l1 DZTLD`IV'_l1 DO`IV'_l1) _I* [aw=wt3], vce(cl clstr)
  \ qui test `ztest'=DO`SH'_l1 \ qui estadd r(p)
\ xi i.sic2 i.year
\ qui eststo: ivregress 2sls DlX_l0 DlX_l1 (DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1=DZTLU`IV'_l1 DZTLD`IV'_l1 DO`IV'_l1) _I* [aw=wt1], vce(cl clstr)
  \ qui test `ztest'=DO`SH'_l1 \ qui estadd r(p)
\ xi i.sic3 i.year
\ qui eststo: ivregress 2sls DlX_l0 DlX_l1 (DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1=DZTLU`IV'_l1 DZTLD`IV'_l1 DO`IV'_l1) _I* [aw=wt1], vce(cl clstr)
  \ qui test `ztest'=DO`SH'_l1 \ qui estadd r(p)
\ xi i.sic87dd i.year
\ qui eststo: ivregress 2sls DlX_l0 DlX_l1 (DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1=DZTLU`IV'_l1 DZTLD`IV'_l1 DO`IV'_l1) _I* [aw=wt1], vce(cl clstr)
  \ qui test `ztest'=DO`SH'_l1 \ qui estadd r(p)
\ tempfile specs
\ esttab * using "`specs'.csv",
	b(%9.3f) se(%9.3f)
	o(DlX_l1 DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1)
	k(DlX_l1 DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1)
	star(* .10 ** .05 *** .01) nonotes label
	stats(N p, fmt(%4.0f %9.3f %9.3f %9.3f))
	replace
\ insheet using "`specs'.csv", comma clear
\ export excel "nw-macro.xlsx", sheetreplace sheet(IV2-X);

*** Robustness table -- Theoretically Precise;
for any `znberT':
\ use if DO`SH'_l1!=. using ./temp/nw-macro2a1, clear 
\ eststo clear
\ qui eststo: ivregress 2sls DlX_l0 DlX_l1 (DZNLU`SH'_l1 DZNLD`SH'_l1 DZDLU`SH'_l1=DZNLU`IV'_l1 DZNLD`IV'_l1 DZDLU`IV'_l1) _I* [aw=wt1], vce(cl clstr)
  \ qui test `ztest2'=DZDLU`SH'_l1 \ qui estadd r(p)
\ qui eststo: ivregress 2sls DlX_l0 DlX_l1 (DZNLU`SH'_l1 DZNLD`SH'_l1=DZNLU`IV'_l1 DZNLD`IV'_l1) _I* [aw=wt1], vce(cl clstr)
  \ qui test `ztest2'=1e5 \ qui estadd r(p)
\ qui eststo: ivregress 2sls DlX_l0 DlX_l1 (DZNLU`SH'_l1 DZNLD`SH'_l1 DZDLU`SH'_l1=DZNLU`IV'_l1 DZNLD`IV'_l1 DZDLU`IV'_l1) _I* [aw=wt2], vce(cl clstr)
  \ qui test `ztest2'=DZDLU`SH'_l1 \ qui estadd r(p)
\ qui eststo: ivregress 2sls DlX_l0 DlX_l1 (DZNLU`SH'_l1 DZNLD`SH'_l1 DZDLU`SH'_l1=DZNLU`IV'_l1 DZNLD`IV'_l1 DZDLU`IV'_l1) _I* [aw=wt3], vce(cl clstr)
  \ qui test `ztest2'=DZDLU`SH'_l1 \ qui estadd r(p)
\ xi i.sic2 i.year
\ qui eststo: ivregress 2sls DlX_l0 DlX_l1 (DZNLU`SH'_l1 DZNLD`SH'_l1 DZDLU`SH'_l1=DZNLU`IV'_l1 DZNLD`IV'_l1 DZDLU`IV'_l1) _I* [aw=wt1], vce(cl clstr)
  \ qui test `ztest2'=DZDLU`SH'_l1 \ qui estadd r(p)
\ xi i.sic3 i.year
\ qui eststo: ivregress 2sls DlX_l0 DlX_l1 (DZNLU`SH'_l1 DZNLD`SH'_l1 DZDLU`SH'_l1=DZNLU`IV'_l1 DZNLD`IV'_l1 DZDLU`IV'_l1) _I* [aw=wt1], vce(cl clstr)
  \ qui test `ztest2'=DZDLU`SH'_l1 \ qui estadd r(p)
\ xi i.sic87dd i.year
\ qui eststo: ivregress 2sls DlX_l0 DlX_l1 (DZNLU`SH'_l1 DZNLD`SH'_l1 DZDLU`SH'_l1=DZNLU`IV'_l1 DZNLD`IV'_l1 DZDLU`IV'_l1) _I* [aw=wt1], vce(cl clstr)
  \ qui test `ztest2'=DZDLU`SH'_l1 \ qui estadd r(p)
\ tempfile specs
\ esttab * using "`specs'.csv",
	b(%9.3f) se(%9.3f)
	o(DlX_l1 DZNLU`SH'_l1 DZNLD`SH'_l1 DZDLU`SH'_l1)
	k(DlX_l1 DZNLU`SH'_l1 DZNLD`SH'_l1 DZDLU`SH'_l1)
	star(* .10 ** .05 *** .01) nonotes label
	stats(N p, fmt(%4.0f %9.3f %9.3f %9.3f))
	replace
\ insheet using "`specs'.csv", comma clear
\ export excel "nw-macro.xlsx", sheetreplace sheet(IV2b-X);

*** Lag table;
for any `znberT':
\ eststo clear
\ use if DO`SH'_l1!=. using ./temp/nw-macro2a1, clear 
\ qui eststo: ivregress 2sls DlX_l0 DlX_l1 (DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1=DZTLU`IV'_l1 DZTLD`IV'_l1 DO`IV'_l1) _I* [aw=wt1], vce(cl clstr)
  \ qui test `ztest'=DO`SH'_l1 \ qui estadd r(p)
\ use ./temp/nw-macro2a2, clear 
\ qui eststo: ivregress 2sls DlX_l0 DlX_l1 (DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1=DZTLU`IV'_l1 DZTLD`IV'_l1 DO`IV'_l1) _I* [aw=wt1], vce(cl clstr)
  \ qui test `ztest'=DO`SH'_l1 \ qui estadd r(p)
\ use ./temp/nw-macro2a3, clear 
\ qui eststo: ivregress 2sls DlX_l0 DlX_l1 (DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1=DZTLU`IV'_l1 DZTLD`IV'_l1 DO`IV'_l1) _I* [aw=wt1], vce(cl clstr)
  \ qui test `ztest'=DO`SH'_l1 \ qui estadd r(p)
\ use ./temp/nw-macro2a4, clear 
\ qui eststo: ivregress 2sls DlX_l0 DlX_l1 (DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1=DZTLU`IV'_l1 DZTLD`IV'_l1 DO`IV'_l1) _I* [aw=wt1], vce(cl clstr)
  \ qui test `ztest'=DO`SH'_l1 \ qui estadd r(p)
\ use ./temp/nw-macro2a5, clear 
\ qui eststo: ivregress 2sls DlX_l0 DlX_l1 (DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1=DZTLU`IV'_l1 DZTLD`IV'_l1 DO`IV'_l1) _I* [aw=wt1], vce(cl clstr)
  \ qui test `ztest'=DO`SH'_l1 \ qui estadd r(p)
\ tempfile specs
\ esttab * using "`specs'.csv",
	b(%9.3f) se(%9.3f)
	o(DlX_l1 DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1)
	k(DlX_l1 DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1)
	star(* .10 ** .05 *** .01) nonotes label
	stats(N p, fmt(%4.0f %9.3f %9.3f %9.3f))
	replace
\ insheet using "`specs'.csv", comma clear
\ export excel "nw-macro.xlsx", sheetreplace sheet(IV3-X);

*** Lag table -- Theoretically Precise;
for any `znberT':
\ eststo clear
\ use if DO`SH'_l1!=. using ./temp/nw-macro2a1, clear 
\ qui eststo: ivregress 2sls DlX_l0 DlX_l1 (DZNLU`SH'_l1 DZNLD`SH'_l1 DZDLU`SH'_l1=DZNLU`IV'_l1 DZNLD`IV'_l1 DZDLU`IV'_l1) _I* [aw=wt1], vce(cl clstr)
  \ qui test `ztest2'=DZDLU`SH'_l1 \ qui estadd r(p)
\ use ./temp/nw-macro2a2, clear 
\ qui eststo: ivregress 2sls DlX_l0 DlX_l1 (DZNLU`SH'_l1 DZNLD`SH'_l1 DZDLU`SH'_l1=DZNLU`IV'_l1 DZNLD`IV'_l1 DZDLU`IV'_l1) _I* [aw=wt1], vce(cl clstr)
  \ qui test `ztest2'=DZDLU`SH'_l1 \ qui estadd r(p)
\ use ./temp/nw-macro2a3, clear 
\ qui eststo: ivregress 2sls DlX_l0 DlX_l1 (DZNLU`SH'_l1 DZNLD`SH'_l1 DZDLU`SH'_l1=DZNLU`IV'_l1 DZNLD`IV'_l1 DZDLU`IV'_l1) _I* [aw=wt1], vce(cl clstr)
  \ qui test `ztest2'=DZDLU`SH'_l1 \ qui estadd r(p)
\ use ./temp/nw-macro2a4, clear 
\ qui eststo: ivregress 2sls DlX_l0 DlX_l1 (DZNLU`SH'_l1 DZNLD`SH'_l1 DZDLU`SH'_l1=DZNLU`IV'_l1 DZNLD`IV'_l1 DZDLU`IV'_l1) _I* [aw=wt1], vce(cl clstr)
  \ qui test `ztest2'=DZDLU`SH'_l1 \ qui estadd r(p)
\ use ./temp/nw-macro2a5, clear 
\ qui eststo: ivregress 2sls DlX_l0 DlX_l1 (DZNLU`SH'_l1 DZNLD`SH'_l1 DZDLU`SH'_l1=DZNLU`IV'_l1 DZNLD`IV'_l1 DZDLU`IV'_l1) _I* [aw=wt1], vce(cl clstr)
  \ qui test `ztest2'=DZDLU`SH'_l1 \ qui estadd r(p)
\ tempfile specs
\ esttab * using "`specs'.csv",
	b(%9.3f) se(%9.3f)
	o(DlX_l1 DZNLU`SH'_l1 DZNLD`SH'_l1 DZDLU`SH'_l1)
	k(DlX_l1 DZNLU`SH'_l1 DZNLD`SH'_l1 DZDLU`SH'_l1)
	star(* .10 ** .05 *** .01) nonotes label
	stats(N p, fmt(%4.0f %9.3f %9.3f %9.3f))
	replace
\ insheet using "`specs'.csv", comma clear
\ export excel "nw-macro.xlsx", sheetreplace sheet(IV3b-X);

*** Comparison of sales-vadd variants;
use if DO`SH'_l1!=. using ./temp/nw-macro2a1, clear;
eststo clear; 
for any nber_rvadd nber_vadd nber_rsales nber_sales:
\ gen Tlag1=DlX_l1
\ qui eststo: ivregress 2sls DlX_l0 Tlag1 (DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1=DZTLU`IV'_l1 DZTLD`IV'_l1 DO`IV'_l1) _I* [aw=wt1], cl(clstr)
\ drop Tlag*;
tempfile specs;
esttab * using "`specs'.csv",
	b(%9.3f) se(%9.3f)
	o(Tlag1 DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1)
	k(Tlag1 DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1)
	star(* .10 ** .05 *** .01) nonotes label
	stats(N, fmt(%4.0f %9.3f %9.3f %9.3f))
	replace;
insheet using "`specs'.csv", comma clear;
export excel "nw-macro.xlsx", sheetreplace sheet(IV4);

*** Psi estimates table;
use if DO`SH'_l1!=. using ./temp/nw-macro2a1, clear; 
eststo clear;
for any `znberT':
\ gen Tlag1=DlX_l1
\ qui eststo: ivregress 2sls DlX_l0 Tlag1 (DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1=DZTLU`IV'_l1 DZTLD`IV'_l1 DO`IV'_l1) _I* [aw=wt1], cl(clstr)
\ gen DVtemp=DlX_l0-0.0*Tlag1
\ qui eststo: ivregress 2sls DVtemp (DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1=DZTLU`IV'_l1 DZTLD`IV'_l1 DO`IV'_l1) _I* [aw=wt1], cl(clstr)
\ replace DVtemp=DlX_l0-0.1*Tlag1
\ qui eststo: ivregress 2sls DVtemp (DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1=DZTLU`IV'_l1 DZTLD`IV'_l1 DO`IV'_l1) _I* [aw=wt1], cl(clstr)
\ replace DVtemp=DlX_l0-0.2*Tlag1
\ qui eststo: ivregress 2sls DVtemp (DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1=DZTLU`IV'_l1 DZTLD`IV'_l1 DO`IV'_l1) _I* [aw=wt1], cl(clstr)
\ replace DVtemp=DlX_l0-0.3*Tlag1
\ qui eststo: ivregress 2sls DVtemp (DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1=DZTLU`IV'_l1 DZTLD`IV'_l1 DO`IV'_l1) _I* [aw=wt1], cl(clstr)
\ replace DVtemp=DlX_l0-0.4*Tlag1
\ qui eststo: ivregress 2sls DVtemp (DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1=DZTLU`IV'_l1 DZTLD`IV'_l1 DO`IV'_l1) _I* [aw=wt1], cl(clstr)
\ replace DVtemp=DlX_l0-0.5*Tlag1
\ qui eststo: ivregress 2sls DVtemp (DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1=DZTLU`IV'_l1 DZTLD`IV'_l1 DO`IV'_l1) _I* [aw=wt1], cl(clstr)
\ replace DVtemp=DlX_l0-0.6*Tlag1
\ qui eststo: ivregress 2sls DVtemp (DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1=DZTLU`IV'_l1 DZTLD`IV'_l1 DO`IV'_l1) _I* [aw=wt1], cl(clstr)
\ replace DVtemp=DlX_l0-0.7*Tlag1
\ qui eststo: ivregress 2sls DVtemp (DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1=DZTLU`IV'_l1 DZTLD`IV'_l1 DO`IV'_l1) _I* [aw=wt1], cl(clstr)
\ replace DVtemp=DlX_l0-0.8*Tlag1
\ qui eststo: ivregress 2sls DVtemp (DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1=DZTLU`IV'_l1 DZTLD`IV'_l1 DO`IV'_l1) _I* [aw=wt1], cl(clstr)
\ replace DVtemp=DlX_l0-0.9*Tlag1
\ qui eststo: ivregress 2sls DVtemp (DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1=DZTLU`IV'_l1 DZTLD`IV'_l1 DO`IV'_l1) _I* [aw=wt1], cl(clstr)
\ replace DVtemp=DlX_l0-1.0*Tlag1
\ qui eststo: ivregress 2sls DVtemp (DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1=DZTLU`IV'_l1 DZTLD`IV'_l1 DO`IV'_l1) _I* [aw=wt1], cl(clstr)
\ drop DVtemp Tlag*;
tempfile specs;
esttab * using "`specs'.csv",
	b(%9.3f) se(%9.3f)
	o(Tlag1 DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1)
	k(Tlag1 DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1)
	star(* .10 ** .05 *** .01) nonotes label
	stats(N, fmt(%4.0f %9.3f %9.3f %9.3f))
	replace;
insheet using "`specs'.csv", comma clear;
export excel "nw-macro.xlsx", sheetreplace sheet(IV5);

*** Variable table with extra lags for appendix summation;
use ./temp/nw-macro2a1, clear; 
foreach SH in l_import_usch {; 
for any `znberT':
\ gen Tlag1=DlX_l1
\ gen Tlag2=DlX_l2
\ gen Tlag3=DlX_l3
\ qui ivregress 2sls DlX_l0 Tlag1 Tlag2 Tlag3 (DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1=DZTLU`IV'_l1 DZTLD`IV'_l1 DO`IV'_l1) _I* [aw=wt1], vce(cl clstr)
\ lincom DZTLU`SH'_l1 
\ lincom DZTLD`SH'_l1 
\ lincom DO`SH'_l1 
\ qui ivregress 2sls DlX_l0 Tlag1 Tlag2 Tlag3 (DZTLU`SH'_l1 DZTLD`SH'_l1 DO`SH'_l1 DO`SH'_l2 DO`SH'_l3=DZTLU`IV'_l1 DZTLD`IV'_l1 DO`IV'_l1 DO`IV'_l2 DO`IV'_l3) _I* [aw=wt1], vce(cl clstr)
\ lincom DZTLU`SH'_l1 
\ lincom DZTLD`SH'_l1 
\ lincom DO`SH'_l1+DO`SH'_l2+DO`SH'_l3  
\ qui ivregress 2sls DlX_l0 Tlag1 Tlag2 Tlag3 (DZTLU`SH'_l1 DZTLU`SH'_l2 DZTLU`SH'_l3 DZTLD`SH'_l1 DZTLD`SH'_l2 DZTLD`SH'_l3 DO`SH'_l1=DZTLU`IV'_l1 DZTLU`IV'_l2 DZTLU`IV'_l3 DZTLD`IV'_l1 DZTLD`IV'_l2 DZTLD`IV'_l3 DO`IV'_l1) _I* [aw=wt1], vce(cl clstr)
\ lincom DZTLU`SH'_l1+DZTLU`SH'_l2+DZTLU`SH'_l3  
\ lincom DZTLD`SH'_l1+DZTLD`SH'_l2+DZTLD`SH'_l3 
\ lincom DO`SH'_l1 
\ qui ivregress 2sls DlX_l0 Tlag1 Tlag2 Tlag3 (DZTLU`SH'_l1 DZTLU`SH'_l2 DZTLU`SH'_l3 DZTLD`SH'_l1 DZTLD`SH'_l2 DZTLD`SH'_l3 DO`SH'_l1 DO`SH'_l2 DO`SH'_l3=DZTLU`IV'_l1 DZTLU`IV'_l2 DZTLU`IV'_l3 DZTLD`IV'_l1 DZTLD`IV'_l2 DZTLD`IV'_l3 DO`IV'_l1 DO`IV'_l2 DO`IV'_l3) _I* [aw=wt1], vce(cl clstr)
\ lincom DZTLU`SH'_l1+DZTLU`SH'_l2+DZTLU`SH'_l3  
\ lincom DZTLD`SH'_l1+DZTLD`SH'_l2+DZTLD`SH'_l3
\ lincom DO`SH'_l1+DO`SH'_l2+DO`SH'_l3
\ drop Tlag*;
};

**********************************;
**********************************;
*** IV Multi-Shock Estimations ***;
**********************************;
**********************************;

local TSH l_import_usch;
local FSH esfed;
local PSH ltfp4;
local USH lfuct;

*** Combined analysis without patenting;
use if DO`TSH'_l1!=. & DO`FSH'_l1!=. using ./temp/nw-macro2a1, clear; 
eststo clear;
for any `znberT':
\ gen Tlag1=DlX_l1
\ gen Tlag2=DlX_l2
\ gen Tlag3=DlX_l3
\ qui eststo: ivregress 2sls DlX_l0 Tlag1 
                          (DZTLU`TSH'_l1 DZTLD`TSH'_l1 DO`TSH'_l1=DZTLU`IV'_l1 DZTLD`IV'_l1 DO`IV'_l1)
                          DZTLU`FSH'_l1 DZTLD`FSH'_l1 DO`FSH'_l1
                          DZTLU`PSH'_l1 DZTLD`PSH'_l1 DO`PSH'_l1
                          _I* [aw=wt1], vce(cl clstr)
  \ qui test DZTLD`TSH'_l1=DZTLD`FSH'_l1 \ qui estadd r(p)
\ qui eststo: ivregress 2sls DlX_l0 Tlag1 Tlag2 Tlag3  
                          (DZTLU`TSH'_l1 DZTLD`TSH'_l1 DO`TSH'_l1=DZTLU`IV'_l1 DZTLD`IV'_l1 DO`IV'_l1)
                          DZTLU`FSH'_l1 DZTLD`FSH'_l1 DO`FSH'_l1
                          DZTLU`PSH'_l1 DZTLD`PSH'_l1 DO`PSH'_l1
                          _I* [aw=wt1], vce(cl clstr)
  \ qui test DZTLD`TSH'_l1=DZTLD`FSH'_l1 \ qui estadd r(p)
\ drop Tlag*;
tempfile specs;
esttab * using "`specs'.csv",
	b(%9.3f) se(%9.3f)
	o(Tlag1 Tlag2 Tlag3 DZTLU`TSH'_l1 DZTLD`TSH'_l1 DO`TSH'_l1 DZTLU`FSH'_l1 DZTLD`FSH'_l1 DO`FSH'_l1 DZTLU`PSH'_l1 DZTLD`PSH'_l1 DO`PSH'_l1)
	k(Tlag1 Tlag2 Tlag3 DZTLU`TSH'_l1 DZTLD`TSH'_l1 DO`TSH'_l1 DZTLU`FSH'_l1 DZTLD`FSH'_l1 DO`FSH'_l1 DZTLU`PSH'_l1 DZTLD`PSH'_l1 DO`PSH'_l1)
	star(* .10 ** .05 *** .01) nonotes label
	stats(N p, fmt(%4.0f %9.3f %9.3f %9.3f))
	replace;
insheet using "`specs'.csv", comma clear;
export excel "nw-macro.xlsx", sheetreplace sheet(IVFull1);

*** Combined analysis adding in patents;
use if DO`TSH'_l1!=. & DO`FSH'_l1!=. using ./temp/nw-macro2a1, clear; 
eststo clear;
for any `znberT':
\ gen Tlag1=DlX_l1
\ gen Tlag2=DlX_l2
\ gen Tlag3=DlX_l3
\ qui eststo: ivregress 2sls DlX_l0 Tlag1 
                          (DZTLU`TSH'_l1 DZTLD`TSH'_l1 DO`TSH'_l1=DZTLU`IV'_l1 DZTLD`IV'_l1 DO`IV'_l1)
                          DZTLU`FSH'_l1 DZTLD`FSH'_l1 DO`FSH'_l1
                          DZTLU`PSH'_l1 DZTLD`PSH'_l1 DO`PSH'_l1
                          DZTLU`USH'_l1 DZTLD`USH'_l1 DO`USH'_l1
                          _I* [aw=wt1], vce(cl clstr)
  \ qui test DZTLD`TSH'_l1=DZTLD`FSH'_l1 \ qui estadd r(p)
\ qui eststo: ivregress 2sls DlX_l0 Tlag1 Tlag2 Tlag3  
                          (DZTLU`TSH'_l1 DZTLD`TSH'_l1 DO`TSH'_l1=DZTLU`IV'_l1 DZTLD`IV'_l1 DO`IV'_l1)
                          DZTLU`FSH'_l1 DZTLD`FSH'_l1 DO`FSH'_l1
                          DZTLU`PSH'_l1 DZTLD`PSH'_l1 DO`PSH'_l1
                          DZTLU`USH'_l1 DZTLD`USH'_l1 DO`USH'_l1
                          _I* [aw=wt1], vce(cl clstr)
  \ qui test DZTLD`TSH'_l1=DZTLD`FSH'_l1 \ qui estadd r(p)
\ drop Tlag*;
tempfile specs;
esttab * using "`specs'.csv",
	b(%9.3f) se(%9.3f)
	o(Tlag1 Tlag2 Tlag3 DZTLU`TSH'_l1 DZTLD`TSH'_l1 DO`TSH'_l1 DZTLU`FSH'_l1 DZTLD`FSH'_l1 DO`FSH'_l1 DZTLU`PSH'_l1 DZTLD`PSH'_l1 DO`PSH'_l1 DZTLU`USH'_l1 DZTLD`USH'_l1 DO`USH'_l1)
	k(Tlag1 Tlag2 Tlag3 DZTLU`TSH'_l1 DZTLD`TSH'_l1 DO`TSH'_l1 DZTLU`FSH'_l1 DZTLD`FSH'_l1 DO`FSH'_l1 DZTLU`PSH'_l1 DZTLD`PSH'_l1 DO`PSH'_l1 DZTLU`USH'_l1 DZTLD`USH'_l1 DO`USH'_l1)
	star(* .10 ** .05 *** .01) nonotes label
	stats(N p, fmt(%4.0f %9.3f %9.3f %9.3f))
	replace;
insheet using "`specs'.csv", comma clear;
export excel "nw-macro.xlsx", sheetreplace sheet(IVFull2);

*** Combined analysis with geo;
use if DO`TSH'_l1!=. & DO`FSH'_l1!=. using ./temp/nw-macro2a1, clear; 
eststo clear;
for any `znberT':
\ gen Tlag1=DlX_l1
\ gen Tlag2=DlX_l2
\ gen Tlag3=DlX_l3
\ qui eststo: ivregress 2sls DlX_l0 Tlag1 
                          (D`GEO'`TSH'_l1 DO`TSH'_l1=D`GEO'`IV'_l1 DO`IV'_l1)
                          D`GEO'`FSH'_l1 DO`FSH'_l1
                          D`GEO'`PSH'_l1 DO`PSH'_l1
                          D`GEO'`USH'_l1 DO`USH'_l1
                          _I* [aw=wt1], vce(cl clstr)
\ qui eststo: ivregress 2sls DlX_l0 Tlag1 
                          (D`GEO'`TSH'_l1 DZTLU`TSH'_l1 DZTLD`TSH'_l1 DO`TSH'_l1=D`GEO'`IV'_l1 DZTLU`IV'_l1 DZTLD`IV'_l1 DO`IV'_l1)
                          D`GEO'`FSH'_l1 DZTLU`FSH'_l1 DZTLD`FSH'_l1 DO`FSH'_l1
                          D`GEO'`PSH'_l1 DZTLU`PSH'_l1 DZTLD`PSH'_l1 DO`PSH'_l1
                          D`GEO'`USH'_l1 DZTLU`USH'_l1 DZTLD`USH'_l1 DO`USH'_l1
                          _I* [aw=wt1], vce(cl clstr)
\ drop Tlag*;
tempfile specs;
esttab * using "`specs'.csv",
	b(%9.3f) se(%9.3f)
	o(Tlag1 D`GEO'`TSH'_l1 DZTLU`TSH'_l1 DZTLD`TSH'_l1 DO`TSH'_l1 D`GEO'`FSH'_l1 DZTLU`FSH'_l1 DZTLD`FSH'_l1 DO`FSH'_l1 D`GEO'`PSH'_l1 DZTLU`PSH'_l1 DZTLD`PSH'_l1 DO`PSH'_l1 D`GEO'`USH'_l1 DZTLU`USH'_l1 DZTLD`USH'_l1 DO`USH'_l1)
	k(Tlag1 D`GEO'`TSH'_l1 DZTLU`TSH'_l1 DZTLD`TSH'_l1 DO`TSH'_l1 D`GEO'`FSH'_l1 DZTLU`FSH'_l1 DZTLD`FSH'_l1 DO`FSH'_l1 D`GEO'`PSH'_l1 DZTLU`PSH'_l1 DZTLD`PSH'_l1 DO`PSH'_l1 D`GEO'`USH'_l1 DZTLU`USH'_l1 DZTLD`USH'_l1 DO`USH'_l1)
	star(* .10 ** .05 *** .01) nonotes label
	stats(N, fmt(%4.0f %9.3f %9.3f %9.3f))
	replace;
insheet using "`specs'.csv", comma clear;
export excel "nw-macro.xlsx", sheetreplace sheet(IVGeo1);

*** Combined analysis with geo - Robustness;
for any `znberT':
\ use if D`GEO'`TSH'_l1!=. using ./temp/nw-macro2a1, clear 
\ eststo clear
\ qui eststo: ivregress 2sls DlX_l0 DlX_l1 (D`GEO'`TSH'_l1 DO`TSH'_l1=D`GEO'`IV'_l1 DO`IV'_l1) D`GEO'`FSH'_l1 DO`FSH'_l1 D`GEO'`PSH'_l1 DO`PSH'_l1 D`GEO'`USH'_l1 DO`USH'_l1 _I* [aw=wt1], vce(cl clstr)
\ qui eststo: ivregress 2sls DlX_l0 DlX_l1 (D`GEO'`TSH'_l1=D`GEO'`IV'_l1) D`GEO'`FSH'_l1 D`GEO'`PSH'_l1 D`GEO'`USH'_l1 _I* [aw=wt1], vce(cl clstr)
\ qui eststo: ivregress 2sls DlX_l0 DlX_l1 (D`GEO'`TSH'_l1 DO`TSH'_l1=D`GEO'`IV'_l1 DO`IV'_l1) D`GEO'`FSH'_l1 DO`FSH'_l1 D`GEO'`PSH'_l1 DO`PSH'_l1 D`GEO'`USH'_l1 DO`USH'_l1 _I* [aw=wt2], vce(cl clstr)
\ qui eststo: ivregress 2sls DlX_l0 DlX_l1 (D`GEO'`TSH'_l1 DO`TSH'_l1=D`GEO'`IV'_l1 DO`IV'_l1) D`GEO'`FSH'_l1 DO`FSH'_l1 D`GEO'`PSH'_l1 DO`PSH'_l1 D`GEO'`USH'_l1 DO`USH'_l1 _I* [aw=wt3], vce(cl clstr)
\ xi i.sic2 i.year
\ qui eststo: ivregress 2sls DlX_l0 DlX_l1 (D`GEO'`TSH'_l1 DO`TSH'_l1=D`GEO'`IV'_l1 DO`IV'_l1) D`GEO'`FSH'_l1 DO`FSH'_l1 D`GEO'`PSH'_l1 DO`PSH'_l1 D`GEO'`USH'_l1 DO`USH'_l1 _I* [aw=wt1], vce(cl clstr)
\ xi i.sic3 i.year
\ qui eststo: ivregress 2sls DlX_l0 DlX_l1 (D`GEO'`TSH'_l1 DO`TSH'_l1=D`GEO'`IV'_l1 DO`IV'_l1) D`GEO'`FSH'_l1 DO`FSH'_l1 D`GEO'`PSH'_l1 DO`PSH'_l1 D`GEO'`USH'_l1 DO`USH'_l1 _I* [aw=wt1], vce(cl clstr)
\ xi i.sic87dd i.year
\ qui eststo: ivregress 2sls DlX_l0 DlX_l1 (D`GEO'`TSH'_l1 DO`TSH'_l1=D`GEO'`IV'_l1 DO`IV'_l1) D`GEO'`FSH'_l1 DO`FSH'_l1 D`GEO'`PSH'_l1 DO`PSH'_l1 D`GEO'`USH'_l1 DO`USH'_l1 _I* [aw=wt1], vce(cl clstr)
\ tempfile specs
\ esttab * using "`specs'.csv",
	b(%9.3f) se(%9.3f)
	o(DlX_l1 D`GEO'`TSH'_l1 DO`TSH'_l1 D`GEO'`FSH'_l1 DO`FSH'_l1 D`GEO'`PSH'_l1 DO`PSH'_l1 D`GEO'`USH'_l1 DO`USH'_l1)
	k(DlX_l1 D`GEO'`TSH'_l1 DO`TSH'_l1 D`GEO'`FSH'_l1 DO`FSH'_l1 D`GEO'`PSH'_l1 DO`PSH'_l1 D`GEO'`USH'_l1 DO`USH'_l1)
	star(* .10 ** .05 *** .01) nonotes label
	stats(N, fmt(%4.0f %9.3f %9.3f %9.3f))
	replace
\ insheet using "`specs'.csv", comma clear
\ export excel "nw-macro.xlsx", sheetreplace sheet(IVGeo2-X);

*** Combined analysis with one geo in sequence;
for any `znberT':
\ use if DO`TSH'_l1!=. & DO`FSH'_l1!=. using ./temp/nw-macro2a1, clear 
\ eststo clear
\ gen Tlag1=DlX_l1
\ gen Tlag2=DlX_l2
\ gen Tlag3=DlX_l3
\ qui eststo: ivregress 2sls DlX_l0 Tlag1 (D`GEO'`TSH'_l1 DO`TSH'_l1=D`GEO'`IV'_l1 DO`IV'_l1) _I* [aw=wt1], vce(cl clstr)
\ qui eststo: ivregress 2sls DlX_l0 Tlag1 (D`GEO'`TSH'_l1 DZTLU`TSH'_l1 DZTLD`TSH'_l1 DO`TSH'_l1=D`GEO'`IV'_l1 DZTLU`IV'_l1 DZTLD`IV'_l1 DO`IV'_l1) _I* [aw=wt1], vce(cl clstr)
\ qui eststo: regress DlX_l0 Tlag1 D`GEO'`FSH'_l1 DO`FSH'_l1 _I* [aw=wt1], vce(cl clstr)
\ qui eststo: regress DlX_l0 Tlag1 D`GEO'`FSH'_l1 DZTLU`FSH'_l1 DZTLD`FSH'_l1 DO`FSH'_l1 _I* [aw=wt1], vce(cl clstr)
\ qui eststo: regress DlX_l0 Tlag1 D`GEO'`PSH'_l1 DO`PSH'_l1 _I* [aw=wt1], vce(cl clstr)
\ qui eststo: regress DlX_l0 Tlag1 D`GEO'`PSH'_l1 DZTLU`PSH'_l1 DZTLD`PSH'_l1 DO`PSH'_l1 _I* [aw=wt1], vce(cl clstr)
\ qui eststo: regress DlX_l0 Tlag1 D`GEO'`USH'_l1 DO`USH'_l1 _I* [aw=wt1], vce(cl clstr)
\ qui eststo: regress DlX_l0 Tlag1 D`GEO'`USH'_l1 DZTLU`USH'_l1 DZTLD`USH'_l1 DO`USH'_l1 _I* [aw=wt1], vce(cl clstr)
\ drop Tlag*
\ tempfile specs
\ esttab * using "`specs'.csv",
	b(%9.3f) se(%9.3f)
	o(Tlag1 D`GEO'`TSH'_l1 DZTLU`TSH'_l1 DZTLD`TSH'_l1 DO`TSH'_l1 D`GEO'`FSH'_l1 DZTLU`FSH'_l1 DZTLD`FSH'_l1 DO`FSH'_l1 D`GEO'`PSH'_l1 DZTLU`PSH'_l1 DZTLD`PSH'_l1 DO`PSH'_l1 D`GEO'`USH'_l1 DZTLU`USH'_l1 DZTLD`USH'_l1 DO`USH'_l1)
	k(Tlag1 D`GEO'`TSH'_l1 DZTLU`TSH'_l1 DZTLD`TSH'_l1 DO`TSH'_l1 D`GEO'`FSH'_l1 DZTLU`FSH'_l1 DZTLD`FSH'_l1 DO`FSH'_l1 D`GEO'`PSH'_l1 DZTLU`PSH'_l1 DZTLD`PSH'_l1 DO`PSH'_l1 D`GEO'`USH'_l1 DZTLU`USH'_l1 DZTLD`USH'_l1 DO`USH'_l1)
	star(* .10 ** .05 *** .01) nonotes label
	stats(N, fmt(%4.0f %9.3f %9.3f %9.3f))
	replace
\ insheet using "`specs'.csv", comma clear
\ export excel "nw-macro.xlsx", sheetreplace sheet(IVGeo3-X);

*** Combined analysis with geo and extra lags;
local TSH l_import_usch;
local IV l_import_otch;
local FSH esfed;
local PSH ltfp4;
local USH lfuct;
local GEO GAD;
use if DO`TSH'_l1!=. & DO`FSH'_l1!=. using ./temp/nw-macro2a1, clear; 
eststo clear;
for any `znberT':
\ gen Tlag1=DlX_l1
\ gen Tlag2=DlX_l2
\ gen Tlag3=DlX_l3
\ qui eststo: ivregress 2sls DlX_l0 Tlag1 Tlag2 Tlag3 
                          (D`GEO'`TSH'_l1 DZTLU`TSH'_l1 DZTLD`TSH'_l1 DO`TSH'_l1=D`GEO'`IV'_l1 DZTLU`IV'_l1 DZTLD`IV'_l1 DO`IV'_l1)
                          D`GEO'`FSH'_l1 DZTLU`FSH'_l1 DZTLD`FSH'_l1 DO`FSH'_l1
                          D`GEO'`PSH'_l1 DZTLU`PSH'_l1 DZTLD`PSH'_l1 DO`PSH'_l1
                          _I* [aw=wt1], vce(cl clstr)
\ qui eststo: ivregress 2sls DlX_l0 Tlag1 Tlag2 Tlag3 
                          (D`GEO'`TSH'_l1 DZTLU`TSH'_l1 DZTLD`TSH'_l1 DO`TSH'_l1=D`GEO'`IV'_l1 DZTLU`IV'_l1 DZTLD`IV'_l1 DO`IV'_l1)
                          D`GEO'`FSH'_l1 DZTLU`FSH'_l1 DZTLD`FSH'_l1 DO`FSH'_l1
                          D`GEO'`PSH'_l1 DZTLU`PSH'_l1 DZTLD`PSH'_l1 DO`PSH'_l1
                          D`GEO'`USH'_l1 DZTLU`USH'_l1 DZTLD`USH'_l1 DO`USH'_l1
                          _I* [aw=wt1], vce(cl clstr)
\ drop Tlag*;
tempfile specs;
esttab * using "`specs'.csv",
	b(%9.3f) se(%9.3f)
	o(Tlag1 Tlag2 Tlag3 D`GEO'`TSH'_l1 DZTLU`TSH'_l1 DZTLD`TSH'_l1 DO`TSH'_l1 D`GEO'`FSH'_l1 DZTLU`FSH'_l1 DZTLD`FSH'_l1 DO`FSH'_l1 D`GEO'`PSH'_l1 DZTLU`PSH'_l1 DZTLD`PSH'_l1 DO`PSH'_l1 D`GEO'`USH'_l1 DZTLU`USH'_l1 DZTLD`USH'_l1 DO`USH'_l1)
	k(Tlag1 Tlag2 Tlag3 D`GEO'`TSH'_l1 DZTLU`TSH'_l1 DZTLD`TSH'_l1 DO`TSH'_l1 D`GEO'`FSH'_l1 DZTLU`FSH'_l1 DZTLD`FSH'_l1 DO`FSH'_l1 D`GEO'`PSH'_l1 DZTLU`PSH'_l1 DZTLD`PSH'_l1 DO`PSH'_l1 D`GEO'`USH'_l1 DZTLU`USH'_l1 DZTLD`USH'_l1 DO`USH'_l1)
	star(* .10 ** .05 *** .01) nonotes label
	stats(N, fmt(%4.0f %9.3f %9.3f %9.3f))
	replace;
insheet using "`specs'.csv", comma clear;
export excel "nw-macro.xlsx", sheetreplace sheet(IVGeo4);

*** End of program;
log close;
libname macware "G:\My Documents\Biostatistics\SAS Macros\Master Library";
options mstored sasmstore=macware;

%macro create_auc_blank()/store source;
data auc_combined;
length marker $ 35; 
length ci_combined $ 35 ;
marker="";
auc=.;
ci2_5=.; 
ci97_5 =.;
ci_combined="";
run;
%mend create_auc_blank;
%macro bootauc_1var(dsn=,marker1=,gold=,id=,boot=200,alpha=0.05)/store source;

%let conflev=%sysevalf(100*(1-&alpha));
%let ll=%sysevalf((&alpha/2)*&boot);
%let ul=%sysevalf((1-(&alpha)/2)*&boot);

proc datasets;delete bootsample bootdist;

proc sql noprint;
  select n(&marker1) into :n
  from &dsn;
quit;

proc surveyselect data=&dsn method=urs n=&n out=bootsample outhits rep=&boot noprint seed=123;
samplingunit &id;
run;

ods listing close; ods html close;
ods output ROCAssociation=roc_assoc;
proc logistic data=bootsample descending;
  by replicate;
  model &gold=&marker1;
	roc  'ROC'  &marker1;
  ods output association=assoc;
run;
ods listing; ods html;

data bootdist;
set roc_assoc;
keep area;
run;

proc sql;
create table tbl_auc as
  select mean(area) as AUC, std(area) as StdErr
  from bootdist;
run; quit;
ods graphics on;
proc univariate data=bootdist;
 var area;
 histogram area;
 output out=uni_ci pctlpts=2.5, 97.5 pctlpre=ci;
 run;
 ods graphics off;
 
data final_auc;
merge tbl_auc uni_ci; run;
data final_auc2; 
set final_auc; 
marker=("&marker1");
ci2_5=round(ci2_5,0.01);
ci97_5=round(ci97_5,0.01);
ci_combined = "(" || catx("-", of ci2_5 ci97_5) || ")";
run;
proc append base=auc_combined data= final_auc2 force; run;


proc datasets library=work nolist;
delete final_auc final_aucf2 bootdist roc_assoc;
run;quit;

%mend bootauc_1var;

/*
example
%bootauc_1var(dsn=pcomb_gs_1000,marker1=adc_median_1000,gold=gs_g,id=mrn);
*/

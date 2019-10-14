/*################################*//*################################*/
/*MACRO:	 CREATE_AUC_BLANK*/
/*Purpose: 	 Creates a blank dataset for storing AUC for each marker*/
/*			 No Input Required*/
/*################################*//*################################*/
%macro create_auc_blank();
data auc_combined;
length marker $ 35 outcome $ 35 ;
outcome="";
marker="";
auc=.;
stderr=.;
ci2_5=.; 
ci97_5 =.;
length ci_combined $ 35;
ci_combined="";
run;
%mend create_auc_blank;
/*################################*//*################################*/
/*MACRO:	 BOOTAUC*/
/*Purpose: 	 Calculates bootstrap confidence intervals*/
/*Variables*/
/*		dsn 	= (REQUIRED) dataset */
/*							-must be stored dataset*/
/*		marker 	= (REQUIRED) continuous or ordinal variable of interest */
/*							-must be of numeric type*/
/*		outcome = (REQUIRED) outcome variable / gold standard */
/*							-can be numeric or character variable type*/
/*		id		= (REQUIRED) observation identifier*/
/*							-can be numeric or character variable type*/
/*		boot	= (OPTIONAL) # bootstrap replicates*/
/*							-must be numeric value*/
/*				   DEFAULT: 100*/
/*		view	= (OPTIONAL) view current AUC combined dataset*/
/*							-must be numeric value*/
/*							-1: print table*/
/*							-All other values: do nothing	*/
/*					DEFUALT: 1*/
/*################################*//*################################*/

%macro bootauc(dsn=,marker=,outcome=,id=,boot=100,view=1);
/*calculates number of unique patients in dataset*/
proc sql noprint;
  select count(distinct &id) into :n
  from &dsn;
quit;
/*creates a dataset with X number of bootstrap replicates*/
proc surveyselect data=&dsn sampsize=&&n method=urs out=bootsample outhits rep=&boot noprint seed=123;
samplingunit &id;
run;
/*turns off output (greatly increases run speed)*/
ods graphics off;  ods exclude all;  ods noresults;
/*runs logistic regression for each sampling replicate and adds */
/*AUC values to table called roc_assoc*/
ods output ROCAssociation=roc_assoc;
proc logistic data=bootsample descending;
 by replicate;
 class &outcome;
 model &outcome=&marker;
 roc  "&marker"  &marker;
run;
/*calculates mean and standard error for AUC from &boot replicates*/
proc sql;
 create table tbl_auc as
 select mean(area) as AUC, std(area) as StdErr
 from roc_assoc;
run; quit;
/*plot distribution of AUC values from &boot replicates*/
/*and output percentiles*/
proc univariate data=roc_assoc;
 var area;
 histogram area;
 output out=uni_ci pctlpts=2.5, 97.5 pctlpre=ci;
 run;
/*turns back on output*/
ods graphics on;  ods exclude none;  ods results;
/*merge the confidence intervals with the mean and standard error*/
data final_auc;
merge tbl_auc uni_ci; 
run;
/*creates datset with labels and creates a combined CI variable for display*/
data final_auc2; 
set final_auc; 
 marker=("&marker");
 outcome=("&outcome");
 ci_combined = "(" || trim(left(round(ci2_5,0.01))) ||"-" || trim(left(round(ci97_5,0.01))) || ")";
run;
/*appends to master dataset*/
proc append base=auc_combined data= final_auc2 force; run;
/*deletes temporary datasets*/
proc datasets library=work nolist;
delete final_auc final_auc2 tbl_auc uni_ci roc_assoc;
run;quit;
/*displays current AUC dataste if view is set to 1*/
%if &view = 1 %then %do;
	proc print data = auc_combined;
	where auc ne . ;
	run;
%end;
%mend bootauc;


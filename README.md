# BootstrapAUC
Bootstrap AUC calculation for univariable ROC curve

Steps for implementation:
1) Pull or Download BootAUCMacro.SAS
2) Run Macro in current SAS iteration OR install to local repository
3) run %create_auc_blank()  once to create your central dataset
4) run  %bootauc(dsn=,marker=,outcome=,id=)
    for each marker


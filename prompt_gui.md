for the random_walk project 

# Shinylive app for Quarto dashboard
+ deploying a 
    + Shinylive for R app within 
    + Quarto 
+ references to digest 
  + https://posit-dev.github.io/r-shinylive/
  + https://quarto-ext.github.io/shinylive/
  + https://r-wasm.github.io/quarto-live/
    + https://parmsam.medium.com/package-tools-i-learned-about-at-posit-conf-2024-dbdd118ec14f§
    + https://github.com/coatless-quarto/r-shinylive-demo
  + https://nrennie.rbind.io/blog/webr-shiny-tidytuesday/

+ add a new vignette called ./inst/qmd/dashboard.qmd
+ it contains a r-shinylive dashboard which runs a shiny app that
  + displays all the inputs needed to run the simulation 
  + to plot and tabulate all the outputs including graphs over different pages. 
+ keep the vignette GUI code in a separate module 
  + to be as independent as possible from the simulation code. 
+ add shiny tests as usual and keep all r-shinylive R code in a package as usual.
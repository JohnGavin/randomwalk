Sys.setenv(R_LIBS_USER = file.path(Sys.getenv("HOME"), "R_libs"))
shinylive::export(appdir = "inst/shiny/dashboard_async",
                  destdir = "docs/articles/dashboard_async")

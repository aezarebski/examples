## This script emulates the behaviour of the ipython notebook of the same name.

library(dplyr)
library(ggplot2) # <--- ggplot is one of the killer apps of R.

## String handling is a little bit fussy in R, the \code{stringr} package is
## what is often used if there is going to be a fair bit of string handling.
source = "WRD_ECDC"
url_str <- sprintf("https://raw.githubusercontent.com/covid19db/data/master/data-epidemiology/covid19db-epidemiology-%s.csv", source)


## The pipe operator, \code{%>%}, is heavily used in the tidyverse and most of
## the main packages that are used now are oriented towards its use.
df_epidemiology <- read.csv(url_str,
                            stringsAsFactors = FALSE) %>%
    select(country, date, confirmed, dead) %>%
    mutate(date = as.Date(date, format = "%d-%m-%y")) %>%
    filter(country == "United_Kingdom")

## To get a print out of the structure of the data frame we have just
## constructed use the following
##
## > str(df_epidemiology)
##
## To get the first couple of rows out of a data frame there is the following.
##
## > head(df_epidemiology)
##

plot_df <- data.frame(date = tail(rev(df_epidemiology$date), -1),
                      daily_deaths = diff(rev(df_epidemiology$dead)))

g <- ggplot(plot_df, aes(x = date, y = daily_deaths)) + geom_point()

print(g)

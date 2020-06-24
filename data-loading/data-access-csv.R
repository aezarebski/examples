## This script emulates the behaviour of the ipython notebook of the same name.

library(httr)
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
    select(date, confirmed, dead, country) %>%
    mutate(date = as.Date(date, format = "%d-%m-%Y")) %>%
    rename(cases = confirmed,
           cumulative_deaths = dead)


## To construct the daily deaths we need the difference of the cumulative
## values, but that means we need to compute the difference in this which is
## country specific so we need to do a bit of munging.

daily_deaths_vector_factory <- function(df) {
    function(country_name) {
        df %>%
            filter(country == country_name) %>%
            use_series("cumulative_death") %>%
            rev %>%
            diff %>%
            {c(0, .)} %>%
            rev
    }
}


df_epidemiology$deaths <- NA
daily_deaths_vector <- daily_deaths_vector_factory(df_epidemiology)

for (country_name in unique(df_epidemiology$country)) {
    mask <- df_epidemiology$country == country_name
    df_epidemiology[mask, "deaths"] <- daily_deaths_vector(country_name)
}


## To get a print out of the structure of the data frame we have just
## constructed use the following
##
## > str(df_epidemiology)
##
## To get the first couple of rows out of a data frame there is the following.
##
## > head(df_epidemiology)
##


## The data is loaded into the shiny app used by COMO from a file
## \code{cases.Rda} and this appears to happen once each time the application is
## started. A simple solution would just be to replace the line at the following
## URL with the code to load in the CSV from OxCDB.
##
## https://github.com/ocelhay/como/blob/master/inst/comoapp/www/source_on_inception.R#L21
##
## So we have a point of comparison, we will load in the data that the
## application is currently using and then format the OxCDB data in the same
## way.


cases_rda_url <- "https://github.com/ocelhay/como/raw/master/inst/comoapp/www/data/cases.Rda"

tmp <- tempfile()
GET(url = cases_rda_url, write_disk(tmp))
load(tmp)


## Make a little plot to check that both data sets look similar.

g <- ggplot(mapping = aes(x = date, y = deaths)) +
    geom_line(data = filter(cases, country == "United_Kingdom"), colour = "blue") +
    geom_point(data = filter(df_epidemiology, country == "United_Kingdom"), colour = "red")
print(g)

## Looks good. So to use the OxCDB data instead of the current RDA file, the
## code above constructing \code{df_epidemiology} could replace line 21 in the
## file linked above and things should work, assuming the order of the records
## in the data frame does not matter. There is only a single country that has a
## name that is mangled, see the code below for example.


## To check which countries have different names there is the following
cases_country_names <- unique(cases$country)
df_epi_country_names <- unique(df_epidemiology$country)
print(setdiff(cases_country_names, df_epi_country_names))

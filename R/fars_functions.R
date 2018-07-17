#' Read a compressed file.
#'
#' This functions allow to read a compressed (.bz2) or a csv file.
#'
#' @param filename A caracter that contains the name of the file with its respective
#' extension.
#'
#' @return This function returns the read data in a "dataframe", "tbl_df", "tbl" format.
#'
#' @note This function will generate an error if the filemane is wrong or have a
#' wrong extension.
#'
#' @importFrom readr read_csv
#' @importFrom dplyr tbl_df
#'
#' @examples
#' library(dplyr)
#' library(readr)
#' fars_read(make_filename(2013))
#' fars_read(make_filename(2014))
#' @export
fars_read <- function(filename) {
        if(!file.exists(filename))
                stop("file '", filename, "' does not exist")
        data <- suppressMessages({
                readr::read_csv(filename, progress = FALSE)
        })
        dplyr::tbl_df(data)
}


#' Create a filename.
#'
#' This functions allow to create a character with a filename, that will have a
#' "csv.bz2" extension. The filename will always be "accident_*.csv.bz2", with
#' the only diference that "*" will be replace by the entered year.
#'
#' @param year an integer that represent a year.
#'
#' @return This function returns a caracter with a filename.
#'
#' @note This function will generate an warning message if the parameter
#' "year" is a character instead a integer.
#'
#' @examples
#' make_filename(2013)
#' make_filename(2014)
#' @export
make_filename <- function(year) {
        year <- as.integer(year)
        system.file("extdata",
                    sprintf("accident_%d.csv.bz2", year),
                    package = "FRED",
                    mustWork = TRUE)
}

#' Select specific variables of the data.
#'
#' This functions allow to select the variable "MONTH" and "YEAR" from
#' the data for the accidents that happend in the year or years entered.
#'
#' @param years an integer that represent a year or years.
#'
#' @return This function returns a list with the variable "MONTH" and "YEAR" for the
#' year or years entered.
#'
#' @note This function will generate an warning message if the year or years entered
#' does not exists in the database.
#'
#' @importFrom readr read_csv
#' @importFrom dplyr tbl_df mutate_ select_
#' @importFrom magrittr %>%
#'
#' @examples
#' fars_read_years(c(2013,2014))
#' fars_read_years(2013)
#' @export
fars_read_years <- function(years) {
        lapply(years, function(year) {
          file <- make_filename(year)
                tryCatch({
                        dat <- fars_read(file)
                        dplyr::mutate_(dat,  year = "YEAR") %>%
                          dplyr::select_("MONTH", "year")
                }, error = function(e) {
                        warning("invalid year: ", year)
                        return(NULL)
                })
        })
}

#' Sumarize accidents by month of a specific year
#'
#' This functions allow to generate a summary of the accidents that happend in a
#' specific year or years.
#'
#' @param years an integer that represent a year or years.
#'
#' @return This function returns a summary for every month of every year
#' in a "dataframe", "tbl_df", "tbl" format.
#'
#' @note This function will generate an warning message if the year or years entered
#' does not exists in the database.
#'
#' @importFrom readr read_csv
#' @importFrom dplyr tbl_df mutate select bind_rows group_by_ summarize_
#' @importFrom tidyr spread_
#' @importFrom magrittr "%>%"
#'
#' @examples
#' fars_summarize_years(c(2013,2014))
#' fars_summarize_years(c(2013,2015))
#' @export
fars_summarize_years <- function(years) {
  dat_list <- fars_read_years(years)
  dplyr::bind_rows(dat_list) %>%
    dplyr::group_by_("year", "MONTH") %>%
    dplyr::summarize_(n = "n()") %>%
    tidyr::spread_("year", "n")
}

#' Plot data accident
#'
#' This functions allow to plot the longitude and latitude of the accidents that
#' happend in a specific state in a specific year
#'
#' @param state.num an integer that represent the number of a state.
#' @param year an integer that represent a year.
#'
#'
#' @return This function returns a graph where can be seen the location (latitude and
#' longitude) of the accident that happend in the state in the year entered.
#'
#' @note This function will generate an error if the year or state
#' does not exists in the database.
#'
#' @importFrom readr read_csv
#' @importFrom dplyr tbl_df filter_
#' @importFrom maps map
#' @importFrom graphics points
#' @importFrom magrittr %>%
#'
#' @examples
#' fars_map_state(27,2013)
#' @export
fars_map_state <- function(state.num, year) {
  filename <- make_filename(year)
  data <- fars_read(filename)
  state.num <- as.integer(state.num)
  if(!(state.num %in% unique(data$STATE))) {
    stop("invalid STATE number: ", state.num)
  }
  data.sub <- dplyr::filter_(data, .dots = paste0("STATE==", state.num))
  if(nrow(data.sub) == 0L) {
    message("no accidents to plot")
    return(invisible(NULL))
  }
  is.na(data.sub$LONGITUD) <- data.sub$LONGITUD > 900
  is.na(data.sub$LATITUDE) <- data.sub$LATITUDE > 90
  with(data.sub, {
    maps::map("state", ylim = range(LATITUDE, na.rm = TRUE),
              xlim = range(LONGITUD, na.rm = TRUE))
    graphics::points(LONGITUD, LATITUDE, pch = 46)
  })
}

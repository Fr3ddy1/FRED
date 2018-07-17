context("make_filename")

make_filename1 <- function(d){
  a1 <- system.file("extdata",
                    paste("accident_",d,".csv.bz2",sep = ""),
                    package = "FRED",
                    mustWork = TRUE)

  return(a1)
}


test_that("Make filename FARS csv test",{
  expect_equal(make_filename(2013),make_filename1(2013))
})

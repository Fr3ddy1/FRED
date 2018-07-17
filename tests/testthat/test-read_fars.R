context("read_fars")

#setwd(system.file("extdata",package = "FRED"))

A <- fars_read(make_filename(2013))

A1 <- read.csv(make_filename(2013))


test_that("Read FARS csv test",{
  expect_equal(class(A)[3],class(A1))
  expect_equal(dim(A),dim(A1))
})

test_that("well names are detected as valid", {
  expect_true(is_valid_well("A1"))
  expect_true(is_valid_well("A1_1"))
  expect_true(is_valid_well("A01"))
  expect_true(is_valid_well("A01_1"))
  expect_false(is_valid_well("test"))
  expect_false(is_valid_well("A01_"))
  expect_false(is_valid_well("A01_1a"))
  expect_false(is_valid_well("aA01_1"))
})

test_that("well names are correctly interpreted", {
  expect_equal(decompose_well_name("A1_1"), list(row = "A", col = 1, pos = 1))
  expect_equal(decompose_well_name("A01_1"), list(row = "A", col = 1, pos = 1))
  expect_equal(decompose_well_name("A1"), list(row = "A", col = 1, pos = as.numeric(NA)))
  expect_equal(decompose_well_name("test"), list(row = as.character(NA), col = as.numeric(NA), pos = as.numeric(NA)))
})

test_that("group function works", {
  expect_equal(groupVector(1:10, 5), list(`1` = c(1:5), `2` = c(6:10)))
  expect_equal(groupVector(1:10, 6), list(`1` = c(1:6), `2` = c(7:10)))
  expect_equal(groupVector(1:10, 15), list(`1` = c(1:10)))
})

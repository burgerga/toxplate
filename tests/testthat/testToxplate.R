context("toxplate")

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

test_that("array generation works", {
  # Create reference matrices
  # 1: Do zigzag, fill by rows, 1 position
  # 2: No zigzag, fill by rows, 1 position
  ref_matrix1 <- matrix(c(1:3,6:4,7:9), ncol = 3, byrow = TRUE)
  ref_matrix2 <- matrix(c(1:9), ncol = 3, byrow = TRUE)

  # test row zigzag
  expect_equivalent(as.matrix(generateLayoutArray("C01", "E03", "rows", 1)[,,1]),
                    ref_matrix1)
  # test row zigzag, starting at 0
  expect_equivalent(as.matrix(generateLayoutArray("C01", "E03", "rows", 0)[,,1]),
                    ref_matrix1 - 1)
  # test column zigzag (transpose ref_matrix1)
  expect_equivalent(as.matrix(generateLayoutArray("C01", "E03", "columns", 1)[,,1]),
                    t(ref_matrix1))
  # test no zigzag
  expect_equivalent(as.matrix(generateLayoutArray("C01", "E03", "notZigzagRowWise", 1)[,,1]),
                    ref_matrix2)
  # test 2 positions, first check 1st position (refmatrix1 * 2 - 1)
  expect_equivalent(as.matrix(generateLayoutArray("C01_1", "E03_2", "rows", 1)[,,1]),
                    ref_matrix1 * 2 - 1)
  # test 2 positions, check 2nd position (refmatrix1 * 2)
  expect_equivalent(as.matrix(generateLayoutArray("C01_1", "E03_2", "rows", 1)[,,2]),
                    ref_matrix1 * 2)
})

#' toxplate: A package for creating plate layout mappings
#'
#' The toxplate package provides functions to creates a plate layout for your experiment based on
#' the top-left and the bottom-right well and a possible zigzag pattern. These layout files can
#' be used to match the location (aka imageNr) in the tif filename to the correct well in the plate.
#' The resulting plate layout data can be exported and used in CellProfiler instead of putting all
#' tifs in separate folders.
#'
#' @docType package
#' @name toxplate
NULL

# Can capture row, column, and optionally position
default_well_matcher <- "^([A-Z])0*(\\d+)(?:_0*(\\d+))?$"

# Split vector into list of vectors of size group_size
groupVector <- function(x, group_size) {
  split(x, ceiling(seq(x)/group_size))
}

is_valid_well <- function(well_name, well_matcher = default_well_matcher) {
  !is.na(stringr::str_match(well_name, well_matcher)[1])
}

is_valid_zigzag <- function(zigzag) {
  zigzag %in% c("rows", "columns", "notZigzagRowWise")
}

decompose_well_name <- function(well_name, well_matcher = default_well_matcher) {
  match <- as.list(stringr::str_match(well_name, well_matcher)[1,-1])
  names(match) <- c("row", "col", "pos")
  match[["col"]] <- as.numeric(match[["col"]])
  match[["pos"]] <- as.numeric(match[["pos"]])
  match
}


getArrayDims <- function(well_dims, zigzag) {
  if(zigzag == "columns") {
    return(c(well_dims[["npos"]], well_dims[["nrow"]], well_dims[["ncol"]]))
  } else {
    return(c(well_dims[["npos"]], well_dims[["ncol"]], well_dims[["nrow"]]))
  }
}

getArrayDimnames <- function(well_dims, zigzag, start_column, start_row) {
  numeric_start_row <- match(start_row, LETTERS)
  if(zigzag == "columns") {
    return(list(pos = seq(well_dims[["npos"]]),
                row = LETTERS[(1:well_dims[["nrow"]]) + numeric_start_row - 1],
                col = seq(well_dims[["ncol"]]) + start_column - 1))
  } else {
    return(list(pos = seq(well_dims[["npos"]]),
                col = seq(well_dims[["ncol"]]) + start_column - 1,
                row = LETTERS[(1:well_dims[["nrow"]]) + numeric_start_row - 1]))
  }
}

getBaseArray <- function(layout_dims, zigzag, left_most_col, top_row, start_location) {
  nloc <- layout_dims[["nrow"]] * layout_dims[["ncol"]] * layout_dims[["npos"]]
  layout_arr <- array(seq(nloc) + start_location - 1, dim = getArrayDims(layout_dims, zigzag),
                      dimnames = getArrayDimnames(layout_dims, zigzag, left_most_col, top_row))
  aperm(layout_arr, c("row", "col", "pos"))
}

getLayoutDims <- function(decomposed_top_left, decomposed_bottom_right) {
  top_row <- match(decomposed_top_left["row"], LETTERS)
  bottom_row <- match(decomposed_bottom_right["row"], LETTERS)
  row_count <- bottom_row - top_row + 1
  column_count <- decomposed_bottom_right[["col"]] - decomposed_top_left[["col"]] + 1
  positions <- if(is.na(decomposed_bottom_right[["pos"]])) 1 else decomposed_bottom_right[["pos"]]
  c("nrow" = row_count, "ncol" = column_count, "npos" = positions)
}

applyZigzagToLayoutArray <- function(layout_arr, layout_dims, zigzag) {
  if(zigzag == "rows" && layout_dims[["nrow"]] >= 2 ) {
    for (row in seq(2, layout_dims[["nrow"]], by = 2)) {
      layout_arr[row,,] <- unlist(lapply(groupVector(layout_arr[row,,], layout_dims[["ncol"]]), rev))
    }
  } else if(zigzag == "columns" && layout_dims[["ncol"]] >= 2) {
    for (col in seq(2, layout_dims[["ncol"]], by = 2)) {
      layout_arr[,col,] <- unlist(lapply(groupVector(layout_arr[,col,], layout_dims[["nrow"]]), rev))
    }
  }
  layout_arr
}

checkArguments <- function(top_left_well, bottom_right_well, zigzag, start_location) {
  assertthat::is.string(top_left_well)
  assertthat::assert_that(is_valid_well(top_left_well))
  assertthat::is.string(bottom_right_well)
  assertthat::assert_that(is_valid_well(bottom_right_well))
  assertthat::is.string(zigzag)
  assertthat::assert_that(is_valid_zigzag(zigzag))
  assertthat::is.number(start_location)
}

generateLayoutArray <- function(top_left_well, bottom_right_well, zigzag, start_location) {
  decomposed_top_left <- decompose_well_name(top_left_well)
  decomposed_bottom_right <- decompose_well_name(bottom_right_well)
  left_most_col <- decomposed_top_left[["col"]]
  top_row <- decomposed_top_left[["row"]]

  layout_dims <- getLayoutDims(decomposed_top_left, decomposed_bottom_right)
  layout_arr <- getBaseArray(layout_dims, zigzag, left_most_col, top_row, start_location)
  layout_arr <- applyZigzagToLayoutArray(layout_arr, layout_dims, zigzag)
  layout_arr
}

layoutArrayToTextDF <- function(layout_arr) {
  apply(layout_arr, c(1,2), paste, collapse = ",")
}

#' @importFrom graphics plot.new
#' @export
getLayoutPicture <- function(top_left_well, bottom_right_well, zigzag, start_location = 1) {
  checkArguments(top_left_well, bottom_right_well, zigzag, start_location)
  layout_arr <- generateLayoutArray(top_left_well, bottom_right_well, zigzag, start_location)

  layoutTextDF <- layoutArrayToTextDF(layout_arr)
  plot.new()
  gridExtra::grid.table(layoutTextDF)
}

#' @export
getLayoutMappingDF <- function(top_left_well, bottom_right_well, zigzag, start_location = 1) {
  checkArguments(top_left_well, bottom_right_well, zigzag, start_location)
  layout_arr <- generateLayoutArray(top_left_well, bottom_right_well, zigzag, start_location)

  layout_df <- as.data.frame.table(layout_arr, responseName = "loc", stringsAsFactors = FALSE)
  layout_df$col <- with(layout_df, as.numeric(col))
  layout_df$pos <- with(layout_df, as.numeric(pos))
  layout_df$well_name <- with(layout_df, paste0(row, sprintf("%02d", col)))
  layout_df$well_name_p <- with(layout_df, paste(well_name, pos, sep = "_"))
  layout_df
}

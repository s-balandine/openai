#' List fine-tune events
#'
#' Returns events related to a specified fine-tune job. See [this
#' page](https://platform.openai.com/docs/api-reference/fine-tunes/events) for
#' details.
#'
#' For arguments description please refer to the [official
#' documentation](https://platform.openai.com/docs/api-reference/fine-tunes/events).
#'
#' @param fine_tune_id required; a length one character vector.
#' @param stream required; defaults to `FALSE`; a length one logical vector.
#'   **Currently is not implemented.**
#' @param openai_api_key required; defaults to `Sys.getenv("OPENAI_API_KEY")`
#'   (i.e., the value is retrieved from the `.Renviron` file); a length one
#'   character vector. Specifies OpenAI API key.
#' @param openai_organization optional; defaults to `NULL`; a length one
#'   character vector. Specifies OpenAI organization.
#' @return Returns a list, elements of which contains information about the
#'   fine-tune events.
#' @examples \dontrun{
#' training_file <- system.file(
#'     "extdata", "sport_prepared_train.jsonl", package = "openai"
#' )
#' validation_file <- system.file(
#'     "extdata", "sport_prepared_train.jsonl", package = "openai"
#' )
#'
#' training_info <- upload_file(training_file, "fine-tune")
#' validation_info <- upload_file(validation_file, "fine-tune")
#'
#' info <- create_fine_tune(
#'     training_file = training_info$id,
#'     validation_file = validation_info$id,
#'     model = "ada",
#'     compute_classification_metrics = TRUE,
#'     classification_positive_class = " baseball" # Mind space in front
#' )
#'
#' id <- ifelse(
#'     length(info$data$id) > 1,
#'     info$data$id[length(info$data$id)],
#'     info$data$id
#' )
#'
#' list_fine_tune_events(fine_tune_id = id)
#' }
#' @family fine-tune functions
#' @export
list_fine_tune_events <- function(
        fine_tune_id,
        stream = FALSE,
        openai_api_url = Sys.getenv("OPENAI_API_URL"),
        openai_api_key = Sys.getenv("OPENAI_API_KEY"),
        openai_organization = NULL
) {

    #---------------------------------------------------------------------------
    # Validate arguments

    assertthat::assert_that(
        assertthat::is.string(fine_tune_id),
        assertthat::noNA(fine_tune_id)
    )

    assertthat::assert_that(
        assertthat::is.flag(stream),
        assertthat::noNA(stream),
        is_false(stream)
    )

    assertthat::assert_that(
        assertthat::is.string(openai_api_key),
        assertthat::noNA(openai_api_key)
    )

    if (!is.null(openai_organization)) {
        assertthat::assert_that(
            assertthat::is.string(openai_organization),
            assertthat::noNA(openai_organization)
        )
    }

    #---------------------------------------------------------------------------
    # Build parameters of the request

    base_url <- glue::glue(
        "{openai_api_url}/v1/fine-tunes/{fine_tune_id}/events"
    )

    headers <- c(
        "Authorization" = paste("Bearer", openai_api_key),
        "Content-Type" = "application/json"
    )

    if (!is.null(openai_organization)) {
        headers["OpenAI-Organization"] <- openai_organization
    }

    #---------------------------------------------------------------------------
    # Build request body

    body <- list()
    body[["stream"]] <- stream

    #---------------------------------------------------------------------------
    # Make a request and parse it

    response <- httr::GET(
        url = base_url,
        httr::add_headers(.headers = headers),
        body = body,
        encode = "json"
    )

    verify_mime_type(response)

    parsed <- response %>%
        httr::content(as = "text", encoding = "UTF-8") %>%
        jsonlite::fromJSON(flatten = TRUE)

    #---------------------------------------------------------------------------
    # Check whether request failed and return parsed

    if (httr::http_error(response)) {
        paste0(
            "OpenAI API request failed [",
            httr::status_code(response),
            "]:\n\n",
            parsed$error$message
        ) %>%
            stop(call. = FALSE)
    }

    parsed

}

# Exercise checking for the BIOS-IN5410 tutorials.
#
# A tutorial activates this by calling, in its global `setup` chunk:
#
#   source("../shared/checkers.R")
#   tutorial_options(exercise.checker = bios_checker)
#
# An exercise is then checked by writing a chunk named `<label>-check`. That
# chunk's last expression must return either TRUE (correct) or a character
# string (incorrect; the string is shown to the student). The helpers below
# follow that convention, so a check chunk is usually a single call:
#
#   ```{r mean-count-check}
#   check_equal(734.5)
#   ```
#
# Inside a check chunk you can use:
#   .result     the value the student's code produced
#   .output     the text their code printed, one element per line
#   .user_code  their code, as a single string
# plus any object their code created.
#
# learnr re-homes this function into the exercise's prep environment, which is
# why everything it needs is defined inside the function body.

bios_checker <- function(label,
                         user_code,
                         solution_code,
                         check_code,
                         envir_result,
                         evaluate_result,
                         envir_prep,
                         last_value,
                         engine,
                         stage,
                         ...) {
    tryCatch({
        praise <- c("Correct!", "Great!", "Exactly right.", "Nice work.")

        if (identical(stage, "code_check")) {
            return(NULL)
        }

        if (identical(stage, "error_check")) {
            return(list(
                correct = FALSE,
                type = "error",
                message = paste0(
                    "Your code stopped with an error: ",
                    conditionMessage(last_value),
                    "\nFix it, check with Run Code until it works, then submit again."
                )
            ))
        }

        code <- paste(check_code, collapse = "\n")
        if (!nzchar(trimws(code))) {
            return(NULL)
        }

        output <- character(0L)
        if (is.list(evaluate_result)) {
            chr <- vapply(evaluate_result, is.character, logical(1L))
            printed <- unlist(evaluate_result[chr], use.names = FALSE)
            if (length(printed) > 0L) {
                output <- unlist(strsplit(printed, "\n", fixed = TRUE), use.names = FALSE)
            }
        }

        env <- new.env(
            parent = if (is.environment(envir_result)) envir_result else globalenv()
        )
        env$.result <- last_value
        env$.output <- output
        env$.user_code <- paste(user_code, collapse = "\n")

        eval(quote({

            .describe <- function(x) {
                if (is.null(x)) {
                    return("NULL")
                }
                if (is.atomic(x) && is.null(dim(x)) && length(x) <= 6L) {
                    return(paste(deparse(x, nlines = 1L), collapse = " "))
                }
                txt <- tryCatch(
                    paste(
                        utils::capture.output(utils::str(x, max.level = 1L, give.attr = FALSE)),
                        collapse = " "
                    ),
                    error = function(e) "something I could not describe"
                )
                txt <- trimws(gsub("\\s+", " ", txt))
                if (nchar(txt) > 120L) return(paste0(substr(txt, 1L, 117L), "...")) else return(txt)
            }

            check_equal <- function(expected, actual = .result, tolerance = 1e-8,
                                    message = NULL) {
                ok <- isTRUE(all.equal(expected, actual, tolerance = tolerance))
                if (ok) {
                    return(TRUE)
                }
                if (!is.null(message)) {
                    return(message)
                }
                return(sprintf(
                    "Not quite. I expected %s, but your code gave %s.",
                    .describe(expected), .describe(actual)
                ))
            }

            check_output <- function(pattern, fixed = FALSE, message = NULL) {
                ok <- length(.output) > 0L &&
                    any(grepl(pattern, .output, fixed = fixed, ignore.case = !fixed))
                if (ok) {
                    return(TRUE)
                }
                if (!is.null(message)) {
                    return(message)
                }
                return(sprintf("I could not find \"%s\" in what the code printed.", pattern))
            }

            check_is <- function(class, actual = .result, message = NULL) {
                if (inherits(actual, class)) {
                    return(TRUE)
                }
                if (!is.null(message)) {
                    return(message)
                }
                return(sprintf(
                    "Your code should produce a %s, but it produced %s instead.",
                    paste(class, collapse = " or "), paste(class(actual), collapse = "/")
                ))
            }

            check_dim <- function(nrow = NULL, ncol = NULL, actual = .result,
                                    message = NULL) {
                d <- dim(actual)
                if (is.null(d)) {
                    return(message %||% "Your code should produce a table (a data frame).")
                }
                if (!is.null(nrow) && d[1L] != nrow) {
                    return(message %||% sprintf(
                        "Your table has %d row(s), but it should have %d.", d[1L], nrow
                    ))
                }
                if (!is.null(ncol) && d[2L] != ncol) {
                    return(message %||% sprintf(
                        "Your table has %d column(s), but it should have %d.", d[2L], ncol
                    ))
                }
                return(TRUE)
            }

            check_names <- function(expected, actual = .result, exact = FALSE,
                                      message = NULL) {
                got <- names(actual)
                ok <- if (exact) identical(got, expected) else all(expected %in% got)
                if (ok) {
                    return(TRUE)
                }
                if (!is.null(message)) {
                    return(message)
                }
                return(sprintf(
                    "I was looking for the name(s) %s, but your result has %s.",
                    paste(expected, collapse = ", "),
                    if (length(got)) paste(got, collapse = ", ") else "none"
                ))
            }

            check_exists <- function(name, message = NULL) {
                if (exists(name, inherits = TRUE)) {
                    return(TRUE)
                }
                message %||% sprintf("I could not find anything called \"%s\".", name)
            }

            # Arguments are evaluated one at a time and checking stops at the first
            # failure, so a later check may safely depend on an earlier one passing.
            check_all <- function(...) {
                exprs <- as.list(substitute(list(...)))[-1]
                where <- parent.frame()
                for (e in exprs) {
                    res <- eval(e, where)
                    if (!isTRUE(res)) {
                        return(res)
                    }
                }
                return(TRUE)
            }

            `%||%` <- function(x, y) if (is.null(x)) y else x

        }), env)

        result <- tryCatch(
            eval(parse(text = code), envir = env),
            error = function(e) e
        )

        if (inherits(result, "condition")) {
            return(list(
                correct = FALSE,
                type = "warning",
                message = paste0(
                    "I could not check this answer because the check itself failed: ",
                    conditionMessage(result),
                    ". This is a problem with the tutorial, not with you, ",
                    "please tell a teacher."
                )
            ))
        }

        if (is.list(result) && "correct" %in% names(result)) {
            return(result)
        }
        if (isTRUE(result)) {
            return(list(correct = TRUE, message = sample(praise, 1L)))
        }
        if (is.character(result)) {
            return(list(correct = FALSE, message = paste(result, collapse = " ")))
        }

        list(correct = FALSE, message = "Not quite, have another go.")

        # A bug in this file must never take the tutorial down with it.
    }, error = function(e) list(
        correct = FALSE,
        type = "warning",
        message = paste0(
            "The answer checker itself failed (", conditionMessage(e), "). ",
            "This is a problem with the tutorial, not with you, ",
            "please tell a teacher."
        )
    ))
}

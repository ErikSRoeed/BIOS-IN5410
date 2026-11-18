# Exercise checking for the BIOS-IN5410 tutorials.
#
# A tutorial activates this by calling, in its global `setup` chunk:
#
# nolint start: commented_code_linter.
#   source(file.path(here, "shared", "checkers.R"))
#   tutorial_options(exercise.checker = bios_checker)
#
# An exercise is then checked by writing a chunk named `<label>-check`. That
# chunk's last expression must return either TRUE (correct) or a character
# string (incorrect; the string is shown to the student). The helpers below
# follow that convention, so a check chunk is a single call:
#
#   check_all(
#       check_uses("for"),
#       check_fun("total_mass_of", list(c(1.5, 2.5)), 4.0)
#   )
# nolint end
#
# Keep check chunks declarative: a chunk should state the requirements and
# leave the control flow to check_all(), which stops at the first failure so
# the student is told the first thing that is wrong. A check must never
# return NULL, or the student gets a generic message instead of an answer.
#
# The helpers are:
#   check_equal(expected, actual)    compare values, with a tolerance
#   check_type(name, type)           an object exists and has the right type
#   check_output(pattern)            the student's code printed something
#   check_uses(what, times)          their code contains a construct or name
#   check_avoids(what)               their code does not take a shortcut
#   check_fun(name, args, expected)  call their function on fresh inputs
#   check_all(...)                   first failing check wins
#
# For the rectangular data tutorial there are also:
#   check_data()                     the answer is a data frame at all
#   check_columns(expected, exactly) the answer has the right columns
#   check_rows(expected)             the answer has the right number of rows
#   check_values(column, expected)   one column holds the right values
#   check_ggplot(geoms, aes, facet)  the answer is a plot of the right shape
#
# Inside a check chunk you can also use:
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
    return(tryCatch({
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

            .type_label <- function(type) {
                labels <- c(
                    double = "a number", integer = "a number",
                    character = "a piece of text, in quotes",
                    logical = "TRUE or FALSE"
                )
                known <- labels[type[type %in% names(labels)]]
                if (length(known) == 0L) {
                    return(paste(type, collapse = " or "))
                }
                return(paste(unique(known), collapse = " or "))
            }

            check_type <- function(name, type, message = NULL) {
                if (!exists(name, inherits = TRUE)) {
                    return(message %||% sprintf(
                        "I could not find anything called `%s`. Check the spelling.", name
                    ))
                }
                found <- typeof(get(name, inherits = TRUE))
                if (found %in% type) {
                    return(TRUE)
                }
                return(message %||% sprintf(
                    "`%s` should be %s, but yours holds %s.",
                    name, .type_label(type), .type_label(found)
                ))
            }

            # Counts how often the student's code mentions `what`, either as a
            # call (`for`, `function`, `paste`) or as a name they referred to.
            # Reading the parsed code rather than the raw text means a `for`
            # inside a comment or a string cannot pass for the real thing.
            .count_uses <- function(what) {
                exprs <- tryCatch(parse(text = .user_code), error = function(e) NULL)
                if (is.null(exprs)) {
                    return(NA_integer_)
                }
                seen <- 0L
                walk <- function(e) {
                    named_head <- is.call(e) && is.name(e[[1L]])
                    if (is.name(e) && as.character(e) %in% what) {
                        seen <<- seen + 1L
                    } else if (named_head && as.character(e[[1L]]) %in% what) {
                        seen <<- seen + 1L
                    }
                    if (is.recursive(e) || is.pairlist(e)) {
                        # The head of a named call is skipped, else `f()` would
                        # count twice: once as a call and once as a bare name.
                        parts <- seq_along(e)
                        if (named_head) {
                            parts <- parts[-1L]
                        }
                        for (i in parts) {
                            tryCatch(walk(e[[i]]), error = function(err) NULL)
                        }
                    }
                    return(invisible(NULL))
                }
                for (e in exprs) {
                    tryCatch(walk(e), error = function(err) NULL)
                }
                return(seen)
            }

            .use_label <- function(what) {
                labels <- list(
                    "function" = "a function of your own, written with `function(...)`",
                    "for" = "a `for` loop",
                    "while" = "a `while` loop",
                    "if" = "an `if` statement"
                )
                if (what[1L] %in% names(labels)) {
                    return(labels[[what[1L]]])
                }
                return(sprintf("`%s`", paste(what, collapse = "` or `")))
            }

            check_uses <- function(what, times = 1L, message = NULL) {
                seen <- .count_uses(what)
                if (is.na(seen)) {
                    return(message %||% paste(
                        "I could not read your code. Press Run Code first, fix any",
                        "errors, then submit again."
                    ))
                }
                if (seen >= times) {
                    return(TRUE)
                }
                if (times > 1L) {
                    return(message %||% sprintf(
                        "This step needs %d separate uses of %s, but I found %d.",
                        times, .use_label(what), seen
                    ))
                }
                return(message %||% sprintf(
                    "This step asks you to use %s, and I cannot find one in your code.",
                    .use_label(what)
                ))
            }

            check_avoids <- function(what, message = NULL) {
                seen <- .count_uses(what)
                if (!is.na(seen) && seen == 0L) {
                    return(TRUE)
                }
                return(message %||% sprintf(
                    "This step is about doing the work yourself, so solve it without %s.",
                    .use_label(what)
                ))
            }

            # Calls the student's function on inputs the exercise never showed
            # them, which is what stops a hard-coded answer from passing.
            check_fun <- function(name, args, expected = NULL, output = NULL,
                                  tolerance = 1e-8, message = NULL) {
                if (!exists(name, inherits = TRUE)) {
                    return(message %||% sprintf(
                        "I could not find a function called `%s()`. Check the spelling.", name
                    ))
                }
                f <- get(name, inherits = TRUE)
                if (!is.function(f)) {
                    return(message %||% sprintf(
                        "`%s` exists, but it is not a function. Define it with `function(...)`.",
                        name
                    ))
                }
                shown <- sprintf("%s(%s)", name, paste(
                    vapply(args, function(a) paste(deparse(a), collapse = ""), character(1L)),
                    collapse = ", "
                ))
                result <- NULL
                printed <- tryCatch(
                    utils::capture.output(result <- do.call(f, args), type = "output"),
                    error = function(e) e
                )
                if (inherits(printed, "condition")) {
                    return(message %||% sprintf(
                        "Calling `%s` stopped with an error: %s",
                        shown, conditionMessage(printed)
                    ))
                }
                if (!is.null(output) && !any(grepl(output, printed, fixed = TRUE))) {
                    return(message %||% sprintf(
                        "I called `%s` and expected it to print \"%s\", but it printed %s.",
                        shown, output,
                        if (length(printed) > 0L) {
                            paste0("\"", printed[1L], "\"")
                        } else {
                            "nothing"
                        }
                    ))
                }
                if (!is.null(expected) &&
                        !isTRUE(all.equal(expected, result, tolerance = tolerance))) {
                    return(message %||% sprintf(
                        "I called `%s` and expected %s, but your function gave %s.",
                        shown, .describe(expected), .describe(result)
                    ))
                }
                return(TRUE)
            }

            .name_list <- function(x) {
                return(paste0("`", x, "`", collapse = ", "))
            }

            check_data <- function(actual = .result, message = NULL) {
                if (is.data.frame(actual)) {
                    return(TRUE)
                }
                return(message %||% sprintf(
                    "This step should give back a table, but your code gave %s.",
                    .describe(actual)
                ))
            }

            check_columns <- function(expected, actual = .result, exactly = FALSE,
                                      message = NULL) {
                is_data <- check_data(actual)
                if (!isTRUE(is_data)) {
                    return(is_data)
                }
                found <- names(actual)
                missing <- setdiff(expected, found)
                if (length(missing) > 0L) {
                    return(message %||% sprintf(
                        "I could not find the column%s %s in your answer, which has %s.",
                        if (length(missing) > 1L) "s" else "",
                        .name_list(missing), .name_list(found)
                    ))
                }
                extra <- setdiff(found, expected)
                if (isTRUE(exactly) && length(extra) > 0L) {
                    return(message %||% sprintf(
                        "Your answer still has the column%s %s, which this step asks you to leave out.",
                        if (length(extra) > 1L) "s" else "", .name_list(extra)
                    ))
                }
                return(TRUE)
            }

            check_rows <- function(expected, actual = .result, message = NULL) {
                is_data <- check_data(actual)
                if (!isTRUE(is_data)) {
                    return(is_data)
                }
                if (identical(as.integer(nrow(actual)), as.integer(expected))) {
                    return(TRUE)
                }
                return(message %||% sprintf(
                    "I expected %d row%s, but your answer has %d.",
                    as.integer(expected), if (as.integer(expected) == 1L) "" else "s",
                    nrow(actual)
                ))
            }

            # Factors are compared as text, so that a student who keeps `Species`
            # as a factor and one who turns it into text both pass.
            check_values <- function(column, expected, actual = .result, sorted = FALSE,
                                     tolerance = 1e-8, message = NULL) {
                has_column <- check_columns(column, actual)
                if (!isTRUE(has_column)) {
                    return(has_column)
                }
                found <- actual[[column]]
                if (is.factor(found)) {
                    found <- as.character(found)
                }
                if (is.factor(expected)) {
                    expected <- as.character(expected)
                }
                if (isTRUE(sorted)) {
                    found <- sort(found)
                    expected <- sort(expected)
                }
                ok <- isTRUE(all.equal(
                    expected, found,
                    tolerance = tolerance, check.attributes = FALSE
                ))
                if (ok) {
                    return(TRUE)
                }
                return(message %||% sprintf(
                    "The `%s` column is not what I expected. I expected %s, but your answer has %s.",
                    column, .describe(expected), .describe(found)
                ))
            }

            # "point" and "geom_point" both mean the GeomPoint class that a built
            # plot actually carries, and a few geoms are built out of another one.
            .geom_class <- function(name) {
                aliases <- c(
                    jitter = "GeomPoint", histogram = "GeomBar", freqpoly = "GeomPath",
                    count = "GeomPoint"
                )
                bare <- sub("^geom_", "", name)
                if (grepl("^Geom", bare)) {
                    return(bare)
                }
                if (bare %in% names(aliases)) {
                    return(unname(aliases[bare]))
                }
                parts <- strsplit(bare, "_", fixed = TRUE)[[1L]]
                camel <- paste0(
                    toupper(substr(parts, 1L, 1L)), substr(parts, 2L, nchar(parts)),
                    collapse = ""
                )
                return(paste0("Geom", camel))
            }

            .geom_label <- function(name) {
                bare <- sub("^geom_", "", name)
                return(sprintf("`geom_%s()`", gsub("|", "()` or `geom_", bare, fixed = TRUE)))
            }

            # A plot's aesthetics may be set in ggplot() or in any layer, so all of
            # them are collapsed into one list, with later settings winning.
            .plot_aes <- function(plot) {
                mappings <- c(list(plot$mapping), lapply(plot$layers, function(l) l$mapping))
                merged <- list()
                for (mapping in mappings) {
                    for (name in names(mapping)) {
                        merged[[name]] <- mapping[[name]]
                    }
                }
                names(merged)[names(merged) == "color"] <- "colour"
                return(merged)
            }

            .aes_label <- function(x) {
                txt <- tryCatch(
                    rlang::as_label(x),
                    error = function(e) paste(deparse(x), collapse = "")
                )
                return(trimws(sub("^~", "", txt)))
            }

            .facet_vars <- function(plot) {
                params <- plot$facet$params
                return(names(c(params$facets, params$rows, params$cols)))
            }

            check_ggplot <- function(actual = .result, geoms = NULL, aes = NULL,
                                     facet = NULL, rows = NULL, message = NULL) {
                if (!inherits(actual, "ggplot")) {
                    return(message %||% sprintf(
                        "This step should give back a plot made with `ggplot()`, but your code gave %s.",
                        if (is.data.frame(actual)) "a table" else .describe(actual)
                    ))
                }
                found_geoms <- vapply(
                    actual$layers, function(l) class(l$geom)[1L], character(1L)
                )
                for (geom in geoms) {
                    wanted <- vapply(
                        strsplit(geom, "|", fixed = TRUE)[[1L]], .geom_class, character(1L)
                    )
                    if (!any(wanted %in% found_geoms)) {
                        return(message %||% sprintf(
                            "I expected a %s layer on this plot, and I cannot find one.",
                            .geom_label(geom)
                        ))
                    }
                }
                mapping <- .plot_aes(actual)
                for (name in names(aes)) {
                    if (!name %in% names(mapping)) {
                        return(message %||% sprintf(
                            "Nothing is mapped to `%s` in your plot. Set it inside `aes()`.", name
                        ))
                    }
                    found <- .aes_label(mapping[[name]])
                    if (!identical(found, aes[[name]])) {
                        return(message %||% sprintf(
                            "Your plot maps `%s` to `%s`, but this step needs `%s` there.",
                            name, found, aes[[name]]
                        ))
                    }
                }
                if (!is.null(facet)) {
                    facetted <- !inherits(actual$facet, "FacetNull")
                    if (isTRUE(facet) && !facetted) {
                        return(message %||% paste(
                            "This plot needs one panel per group, so it needs `facet_wrap()`."
                        ))
                    }
                    if (identical(facet, FALSE) && facetted) {
                        return(message %||% "This step asks for one panel, without facetting.")
                    }
                    if (is.character(facet)) {
                        if (!facetted) {
                            return(message %||% sprintf(
                                "This plot needs to be split into panels by `%s`, with `facet_wrap()`.",
                                facet[1L]
                            ))
                        }
                        missing <- setdiff(facet, .facet_vars(actual))
                        if (length(missing) > 0L) {
                            return(message %||% sprintf(
                                "Your plot is facetted, but not by %s.", .name_list(missing)
                            ))
                        }
                    }
                }
                if (!is.null(rows)) {
                    if (!is.data.frame(actual$data)) {
                        return(message %||% paste(
                            "I could not see the data behind your plot. Pass it to `ggplot()`",
                            "as the first argument, or pipe it in."
                        ))
                    }
                    return(check_rows(rows, actual$data, message = message))
                }
                return(TRUE)
            }

            # Arguments are evaluated one at a time and checking stops at the first
            # failure, so a later check may safely depend on an earlier one passing.
            check_all <- function(...) {
                exprs <- as.list(substitute(list(...)))[-1L]
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
    }, error = function(e) {
        return(list(
            correct = FALSE,
            type = "warning",
            message = paste0(
                "The answer checker itself failed (", conditionMessage(e), "). ",
                "This is a problem with the tutorial, not with you, ",
                "please tell a teacher."
            )
        ))
    }))
}

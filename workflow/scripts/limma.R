# Author: James Ashmore
# Copyright: Copyright 2020, James Ashmore
# Email: james.ashmore@zifornd.com
# License: MIT

modelMatrix <- function(object) {

	# Get phenotype data

	data <- pData(object)

	names <- colnames(data)

	# Set condition factor

	if ("condition" %in% names) {

		condition <- factor(data$condition)

		n.condition <- nlevels(condition)

		is.condition <- n.condition > 1
	
	} else {

		is.condition <- FALSE

	}

	# Set batch factor

	if ("batch" %in% names) {

		batch <- factor(data$batch)

		n.batch <- nlevels(batch)

		is.batch <- n.batch > 1

	} else {

		is.batch <- FALSE

	}

	# Set block factor

	if ("block" %in% names) {

		block <- factor(data$block)

		n.block <- nlevels(block)

		is.block <- n.block > 1

	} else {

		is.block <- FALSE

	}

	# Construct design matrix

	if (is.condition & !is.batch & !is.block) {

		design <- model.matrix(~ 0 + condition)

	}

	if (is.condition & is.batch & !is.block) {

		design <- model.matrix(~ 0 + condition + batch)

	}

	if (is.condition & !is.batch & is.block) {
		
		design <- model.matrix(~ 0 + condition + block)

	}

	if (is.condition & is.batch & is.block) {

		design <- model.matrix(~ 0 + condition + batch + block)

	}

	# Rename condition coefficients

	which.condition <- seq_len(n.condition)

	colnames(design)[which.condition] <- levels(condition)

	# Return design matrix

	design

}

main <- function(input, output, params, log, config) {

    # Log

    out <- file(log$out, open = "wt")

    err <- file(log$err, open = "wt")

    sink(out, type = "output")

    sink(err, type = "message")

    # Script

	library(limma)

	library(oligo)
	
	obj <- readRDS(input$rds)

	mod <- modelMatrix(obj)
	
	fit <- lmFit(obj, mod)

	con <- sapply(config$contrasts, paste, collapse = "-")
	
	mat <- makeContrasts(contrasts = con, levels = colnames(mod))

	fit <- contrasts.fit(fit, mat)

	fit <- eBayes(fit)

	saveRDS(fit, file = output$rds)

}

main(snakemake@input, snakemake@output, snakemake@params, snakemake@log, snakemake@config)
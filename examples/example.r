library(R6)

Product <- R6Class("Product",
  public = list(
    id    = NULL,
    name  = NULL,
    price = NULL,
    stock = NULL,

    initialize = function(id, name, price, stock) {
      stopifnot(is.character(id), is.character(name))
      stopifnot(is.numeric(price), price >= 0)
      stopifnot(is.numeric(stock), stock >= 0)
      self$id    <- id
      self$name  <- name
      self$price <- price
      self$stock <- as.integer(stock)
    },

    format = function(...) {
      sprintf("Product(%s, %s, $%.2f)", self$id, self$name, self$price)
    }
  )
)

Cart <- R6Class("Cart",
  private = list(items = list()),
  public = list(
    add = function(product, qty = 1L) {
      stopifnot(inherits(product, "Product"), qty > 0)
      id <- product$id
      if (!is.null(private$items[[id]])) {
        private$items[[id]]$qty <- private$items[[id]]$qty + qty
      } else {
        private$items[[id]] <- list(product = product, qty = qty)
      }
      invisible(self)
    },

    remove = function(product_id) {
      private$items[[product_id]] <- NULL
      invisible(self)
    },

    subtotal = function() {
      if (length(private$items) == 0) return(0)
      sum(vapply(private$items, function(i) i$product$price * i$qty, numeric(1)))
    },

    total = function(discount_fn = identity) {
      discount_fn(self$subtotal())
    },

    is_empty = function() length(private$items) == 0
  )
)

Repository <- R6Class("Repository",
  private = list(store = list()),
  public = list(
    save = function(key, entity) {
      private$store[[key]] <- entity
      invisible(self)
    },

    find = function(key) {
      private$store[[key]]
    },

    find_or_stop = function(key) {
      entity <- private$store[[key]]
      if (is.null(entity)) stop(sprintf("Not found: %s", key))
      entity
    },

    all = function() unname(private$store)
  )
)

percentage_discount <- function(rate) {
  function(price) price * (1 - rate / 100)
}

fixed_discount <- function(amount) {
  function(price) max(0, price - amount)
}

fibonacci <- function(n) {
  if (n <= 0) return(integer(0))
  seq <- integer(n)
  seq[1] <- 0L
  if (n > 1) seq[2] <- 1L
  for (i in seq_len(max(0, n - 2)) + 2) {
    seq[i] <- seq[i - 1] + seq[i - 2]
  }
  seq
}

sieve <- function(limit) {
  if (limit < 2) return(integer(0))
  flags <- rep(TRUE, limit)
  flags[1] <- FALSE
  for (i in 2:floor(sqrt(limit))) {
    if (flags[i]) {
      j <- seq(i * i, limit, by = i)
      flags[j] <- FALSE
    }
  }
  which(flags)
}

repo <- Repository$new()
repo$save("1", Product$new("1", "Laptop",   999.99, 10))
repo$save("2", Product$new("2", "Mouse",     29.99, 50))
repo$save("3", Product$new("3", "Keyboard",  79.99, 30))

cart <- Cart$new()
cart$add(repo$find_or_stop("1"), 1)
cart$add(repo$find_or_stop("2"), 2)

discount <- percentage_discount(10)
cat(sprintf("Subtotal:   $%.2f\n", cart$subtotal()))
cat(sprintf("After 10%%: $%.2f\n", cart$total(discount)))

affordable <- Filter(function(p) p$price < 100, repo$all())
affordable <- affordable[order(sapply(affordable, function(p) p$price))]
cat("Affordable:", paste(sapply(affordable, function(p) p$name), collapse = ", "), "\n")

cat("Fibonacci(8):", paste(fibonacci(8), collapse = ", "), "\n")
cat("Primes up to 30:", paste(sieve(30), collapse = ", "), "\n")

products_df <- data.frame(
  name  = sapply(repo$all(), function(p) p$name),
  price = sapply(repo$all(), function(p) p$price),
  stock = sapply(repo$all(), function(p) p$stock)
)

cat("\nProducts data frame:\n")
print(products_df[order(products_df$price), ])
cat(sprintf("\nMean price: $%.2f\n", mean(products_df$price)))
cat(sprintf("Total stock: %d\n", sum(products_df$stock)))

# Generates the data needed for the app
# Tests the model on a held-out test set
# Model is 0-gram, 1-gram, and 2-gram of context with a prediction
# backoff when less than 10 occurences of context with a top 5 prediction

set.seed(1234)

library(ngram)
library(tidyverse)

start.time <- Sys.time()

train_size <- 100000
test_size <- 100000

# load the data
twitter <- readLines("en_US.twitter.txt", encoding = "UTF-8", warn = FALSE)
test_indices <- sample(length(twitter), test_size) # set aside tweets for testing
test_data <- twitter[test_indices]
twitter <- twitter[-test_indices]

# prepare the training data
twitter <- twitter %>%
    sample(train_size) %>%
    concatenate %>%
    preprocess(remove.punct = TRUE) %>%
    str_trim

# form bigrams and trigrams
ng2 <- ngram(twitter, n = 2)
ng3 <- ngram(twitter, n = 3)

# split ngrams into context and prediction
x2 <- ng2 %>%
    get.phrasetable %>%
    mutate(ngrams = str_sub(ngrams, 1, nchar(ngrams) - 1)) %>%
    extract(ngrams, c("context", "prediction"), '(.*)\\s+([^ ]+)$')

x3 <- ng3 %>%
    get.phrasetable %>%
    mutate(ngrams = str_sub(ngrams, 1, nchar(ngrams) - 1)) %>%
    extract(ngrams, c("context", "prediction"), '(.*)\\s+([^ ]+)$')

# each context will map to a data frame with a prediction column and a freq column
dic2 <- new.env()
for (i in 1:nrow(x2)) {
    context <- x2$context[i]
    prediction <- x2$prediction[i]
    freq <- x2$freq[i]
    if (exists(context, dic2)) {
        dic2[[context]] <- rbind(dic2[[context]], tibble(prediction = prediction, freq = freq))
    } else {
        dic2[[context]] <- tibble(prediction = prediction, freq = freq)
    }
}

dic3 <- new.env()
for (i in 1:nrow(x3)) {
    context <- x3$context[i]
    prediction <- x3$prediction[i]
    freq <- x3$freq[i]
    if (exists(context, dic3)) {
        dic3[[context]] <- rbind(dic3[[context]], tibble(prediction = prediction, freq = freq))
    } else {
        dic3[[context]] <- tibble(prediction = prediction, freq = freq)
    }
}

# pruning both down to top 5 and pruning away completely those contexts whose
# top 5 predictions have less than 10 occurences
for (context in ls(dic2)) {
    dic2[[context]] <- head(dic2[[context]], n = 5) #take head first since we want to know if top 5 are common
    if (sum(dic2[[context]]$freq) < 10) {
        eval(parse(text = paste0("rm(\"", context, "\", envir = dic2", ")"))) # a little hacky meta-programming
    }
}

for (context in ls(dic3)) {
    dic3[[context]] <- head(dic3[[context]], n = 5)
    if (sum(dic3[[context]]$freq) < 10) {
        eval(parse(text = paste0("rm(\"", context, "\", envir = dic3", ")")))
    }
}

# Predict the top 5 next words based on a two-word context
f <- function(context) {
    if (context %in% c("", " ")) { # special cases
        return(c("the", "to", "a", "and", "of")) 
    }
    if (!exists(context, dic3)) { # not common enough two-word context
        context <- str_split(context, " ")[[1]][2]
        if (!exists(context, dic2)) { # not common enough one-word context
            return(c("the", "to", "a", "and", "of")) 
        }
        x <- dic2[[context]]$prediction
        while (length(x) < 5) {
            x <- c(x, "")
        }
        return(x)
    }
    x<- dic3[[context]]$prediction
    while (length(x) < 5) {
        x <- c(x, "")
    }
    x
}

# Save the environments as lists
list_dic2 <- as.list(dic2)
save(list_dic2, file = "list_dic2.data")
list_dic3 <- as.list(dic3)
save(list_dic3, file = "list_dic3.data")

# convert raw text in context format
process <- function(s) {
    s <- preprocess(s, remove.punct = TRUE)
    s <- str_split(s, " ")[[1]]
    paste(s[length(s) - 1], s[length(s)])
}

# predict the 5 most common next words from raw text
next_word <- function(text) {
    f(process(text))
}

######################################
# Testing ############################
######################################

# Prepare the test data
test_data <- test_data %>%
    concatenate %>%
    preprocess(remove.punct = TRUE) %>%
    str_trim

test_data <- str_split(test_data, pattern = " ")[[1]]
n <- length(test_data) - 2
top5 <- 0
top1 <- 0
for (i in 1:n) {
    context <- paste(test_data[i], test_data[i + 1])
    true_word <- test_data[i + 2]
    preds <- f(context)
    if (preds[1] == true_word) {
        top1 <- top1 + 1
    }
    if (true_word %in% preds) {
        top5 <- top5 + 1
    }
}
top1 <- top1 / n
top5 <- top5 / n

end.time <- Sys.time()

# Saving Test results

fileConn<-file("test_results.txt")
writeLines(paste(c("time elapsed: ", "train size: ", "test size: ", "top 1: ", "top 5: "),
                 c(end.time - start.time, train_size, test_size, top1, top5)), fileConn)
close(fileConn)


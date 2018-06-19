# data-science-capstone
This repo contains my code for the final project of the Coursera Data Science Specialization Capstone.

The project is a shiny app that is meant to mimic a predictive keyboard like you might find on a smartphone. The user types into a text box, and five suggested words are automatically generated. The five words appear on buttons beneath the text box. Clicking a button adds that word to the text box.

The app is available [here](https://jnd18.shinyapps.io/tweet-helper/).

The language model used to generated the suggested words is an ngram backoff model. Basically, we look at the last two words typed, and if they are "in" the model, we use the five words that most commonly follow those two words in the training data. If that context is not in the model, then we look at the last word and see if that context is in the model. If it is we use the five words that mostly commonly follow that word in the training data. If the last word is not in the model, then we just use the five most common words in data. A context is "in" the model if the five most common words that follow the context appear, in total, at least 10 times. Anything less and the context is deemed too rare to be meaningful.

The app folder contains everything needed to run the shiny app locally. However, if you'd like to reproduce my work or use a different number of tweets to train the model, then:
1. Download the data from https://d396qusza40orc.cloudfront.net/dsscapstone/dataset/Coursera-SwiftKey.zip 
2. Unzip and copy the en_US.twitter.txt file to your working directory.
3. Run the ngram_model.R script to produce the list_dic2.data and list_dic3.data files.
4. Copy the list_dic2.data and list_dic3.data files into the app directory.

If you want to use a different text corpus, obviously steps 1 and 2 are not necessary. Use your own text file, and make sure you change the path in line 17 of ngram_model.R.

# nationalParkTwitter
An interactive map to view the National Park System's Twitter feeds.
Simply click on a national park to view its Twitter feed.

I developed this app to learn more about manipulating and visualizing map data and pulling Twitter data using R.
I scraped national park Twitter account data from [this website](https://jasoncochran.com/blog/all-the-national-park-service-twitter-accounts-in-one-place/) using the `rvest` package and from Twitter itself using the `rtweet` package.
I use the `sf` and `leaflet` packages to visualize national parks as polygons overlaid on a map of the U.S.
After joining the account and map data together and filtering to the user-selected national park, I render a `twitter-timeline` HTML element directly in the app.

I did not match every national park with a twitter account, so some are missing. 
Only parks with a solid border have viewable Twitter accounts.

Additionally, I am unable to host this application on my free shinyapps.io account due to memory issues.
I recommend cloning this application locally if you're interested in using it.

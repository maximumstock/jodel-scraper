# jodel-scraper

__Note__: Currently in a non-functional state. Look at [https://github.com/maximumstock/jodel-scraper-js](jodel-scraper-js) for a working JS version.

A scraper for [Jodel](https://www.jodel-app.com) written in Elixir.
Scrapes most recent, discussed and upvoted jodels and stores them in a Postgres database.
This project contains a basic client implementation of the private Jodel API to authorize
and retrieve feeds and further subapplications to scrape and analyze API data.

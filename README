#rhrae

rhrae is a Ruby console application that scrapes dictionary entries from the
Spanish official language authority `Real Academia Española`.

It uses capybara, poltergeist and phantomjs to scrape the RAE website since RAE
uses Javascript to obfuscate the results, requiring a JS enabled scraping
library.

A Dockerfile is included to easily install the needed environment to test
the application, if Docker is available in your machine run:

```
$ cd rhrae
$ docker build -t rhrae .
$ docker run -it rhrae
```

If it's not, use bundler to install the required dependencies and run the
application directly:

```
$ bundle
$ bundle exec ruby rhrae.rb
```

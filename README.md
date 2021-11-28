# Coverage adventures

Collection of scripts to crawl websites and aggegrate coverage data.
See this [article](https://slipperyjoe.xyz/articles/css_coverage_adventures.html) for detailed explanations.

The main scrips is run_get_coverage.sh Project variables (ex: base url) are
hard coded at the top of the script.  This script calls other scripts:
get_coverage.js and extract_urls.sh. See the notes inside the scripts for more
informations. 

## Automatic version:

1.  Choose website entry point (ex: the landing page) and dowload the html document
    wget / curl / puppeteer to download index.html
    Enter appropritate values at top of run_get_coverage.sh script

2.  Put it in data/level_0, DON'T mkdir data/level_1

3.  call run_get_coverage.sh -deck 1

4.  add patterns to non_urls and reject_urls files and re-do cleanup step

    get_coverage.js logs the results of request in log/log_level_0_1. Grep the
    first col for "1" to check urls to rerun

    rinse and repeat until no new urls are found
    
## Manual version:

1.  Choose website entry point (ex: index.html) and dowload page
    wget / curl / puppeteer to download index.html

2.  Get urls out by calling:
        ```sh
        ./extract_urls.sh index.html # Generates index.html.urls file
        ```

3.  Get coverage and page content
        ```sh
        mkdir level_1
        ./get_coverage.js -wsc  \
            -e "button.gdpr-lmd-button.gdpr-lmd-button--main" \
            -p 'https://lemonde.fr' \
            -o '../level_1' \
            -l '../data/log/log_level_1' \
            -f '../data/index.html.urls'
        ```

4.  Get urls out by calling:
        ```sh
        ./extract_urls.sh level_1/* # Generates an .urls file for each file
        ```

5.  Generate level_1_urls  (this is not the real script, see in run_get_coverage.sh)
        ```sh
        cat level_1/*.urls | 
        sort -u | 
        # remove urls with rules in reject_urls
        grep -vf reject_urls | 

        # Get only new urls
        grep -vf index.html.urls > level_1_urls
        ```

        Essentially: 
            -exclude non-urls patterns (like mailto: ) that we may find in a href attribute
            -exclude irrelevant urls (mostly repeated ones like /blog/article-1, blog/article-2)

6. Validate manually:

    Add patterns to non_urls and reject_urls files and re-do cleanup step

    Get_coverage.js logs the results of request in log/log_level_0_1. Grep the
    first column for "1" to check urls to rerun

    Rinse and repeat until no new urls are found


## Analysis

The analysis step is done separately with the script concat_ranges.sh. That way
you can easily recrawl parts of the website, exclude certain pages, only
consider certain resources, etc.  Call it on a resource of interest and/or on a
batch of resources.

This yields
    * a final coverage file (with ranges of used bytes)
    * a final coverage percentage for that resource




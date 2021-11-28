
The main scrips is run_get_coverage.sh
Hard coded project variables (ex: base url) at the top of the script
Calls get_coverage.js and extract_urls.sh and contains cleanup commands

The script can be called just for cleanup once the download has happenened and
you want to re-extract urls for ex.

Automatic version:
--------------------
1.  Choose website entry point (ex: index.html) and dowload page
    wget / curl / puppeteer to download index.html
    Enter appropritate values at top of run_get_coverage.sh script

2.  Put it in level_0, DON'T mkdir level_1

3.  call run_get_coverage.sh -deck 1

4.  add patterns to non_urls and reject_urls files and re-do cleanup step

    get_coverage.js logs the results of request in log/log_level_0_1. Grep the
    first col for "1" to check urls to rerun

    rinse and repeat until no new urls are found
    

Manual version:
--------------------

1.  Choose website entry point (ex: index.html) and dowload page
    wget / curl / puppeteer to download index.html

2.  Get urls out by calling:
        ./extract_urls.sh index.html
        # Generates index.html.urls file

3.  Get coverage and page content
        mkdir level_1
        ./get_coverage.js -wsc  \
            -e "button.gdpr-lmd-button.gdpr-lmd-button--main" \
            -p 'https://lemonde.fr' \
            -o '../level_1' \
            -l '../data/log/log_level_1' \
            -f '../data/index.html.urls'

4.  Get urls out by calling:
        ./extract_urls.sh level_1/*
        # Generates an .urls file for each file

5.  Generate level_1_urls  (this is not the real script, see in run_get_coverage.sh)
        cat level_1/*.urls | 
        sort -u | 
        # remove urls with rules in reject_urls
        grep -vf reject_urls | 

        # Get only new urls
        grep -vf index.html.urls > level_1_urls

        Essentially: 
            -exclude non-urls patterns (like mailto: ) that we may find in a href attribute
            -exclude irrelevant urls (mostly repeated ones like /blog/article-1, blog/article-2)

6. Validate manually, 

    add patterns to non_urls and reject_urls files and re-do cleanup step

    get_coverage.js logs the results of request in log/log_level_0_1. Grep the
    first col for "1" to check urls to rerun

    rinse and repeat until no new urls are found


---------

Analysis step is done separately with concat_ranges.sh
Call it on a resource of interest and/or on a batch of resources
    Ex: get the global coverage for all the resources loaded on the landing page

This yields
    - a final coverage file (with ranges of used code)
    - a final coverage percentage for that resource

Call this script on all the resources loaded in the resource page

To get the total coverage of ANY resource loaded ANYWHERE on the site, we would
need to record the network request list for every page


get_percentage.sh extracts percentages from a .har file (coverage file on only one page)

Restart with a smaller site (my own site for ex)
Then do Slate.fr
Do a series on news sites: "we know news sites are shit, yes but how much"
Do University sites, big companies sites
https://genius.com/

Avoid government sites

Should alias the project in bash
Can I simplify / automate more ?

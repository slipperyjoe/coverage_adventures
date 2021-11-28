#!/usr/bin/node
// -----------------------------------------------------------------------------
// DESCRIPTION:
//    This script uses puppeteer to navigate to a set of pages and save
//    coverage reports. Additionnal actions like clicking on cookie banner can
//    be easily included
//
// AUTHOR:
//			slipperyjoe <contact@slipperyjoe.xyz>
//
// COPYRIGHT:      
//      Copyright © 2021 slipperyjoe. License GPLv3+: GNU GPL version 3
//      or later <https://gnu.org/licenses/gpl.html>.
//      This is free software: you are free to change and redistribute it. There
//      is NO WARRANTY, to the extent permitted by law.
//
// -----------------------------------------------------------------------------
// NOTES:
// lemonde.fr:
// button.gdpr-lmd-button.gdpr-lmd-button--main
//
// echo "/actualites/ /blog/"  | xargs ./test_puppeteer.js -p "https://lemonde.fr
//
//
// -----------------------------------------------------------------------------
//  TODO:
//    add return codes
//    add examples 
// -----------------------------------------------------------------------------
  
const puppeteer = require('puppeteer');
const fs = require('fs');
const yargs = require("yargs");
//const split = require('split');
//const through = require('through');


const options = yargs
    .usage(` Usage: $0 [OPTIONS]... [URL_FILE] `)
// .option("s", { alias: "save", describe: "If set, save page content", type: "boolean", demandOption: true })
//    .demand(1)
    .option("b", { alias: "browser", describe: "Path to browser executable", type: "string", default: "/usr/bin/google-chrome-stable" })
    .option("e", { alias: "element", describe: "Element selector to click on page", type: "string" })
    .option("o", { alias: "outdir", describe: "Output directory for coverage files and saved pages. Default is current directory", type: "string", default: "" })
    .option("p", { alias: "prefix", describe: "Optional URL prefix", type: "string" })
    .option("w", { alias: "write",  describe: "If set, write page content to file", type: "boolean", default: false })
    .option("s", { alias: "scroll",  describe: "If set, scroll to bottom of page", type: "boolean", default: false })
    .option("c", { alias: "coverage", describe: "If set, save page CSS coverage", type: "boolean", default: false })
    .option("f", { alias: "file", describe: "Specify input url batch file, one per line", type: "string", default: "" })
    .option("l", { alias: "log", describe: "Log file", type: "string" })
    .help('h')
    .alias('h', 'help')
    .strict()
    .fail((msg,err) => {
        console.error(msg)
        process.exit(1)
    })
    .argv;

//  CHECKS AND INITIALIZATIONS
// ----------------------------------------------------------------------------

// variables declarations
let coverage_report_path
let css_coverage
let current_url
let page_content_path
var URL_TO_CHECK 
var CURRENT_STATUS = 0
// read urls from input file
// ./script.js -f input_file
if(options.file){
    try {
        const data = fs.readFileSync(options.file, 'utf8');
        // trim() to remove trailing \n that yields an extra empty element
        URL_TO_CHECK = data.trim().split('\n');
    } catch (err) {
        console.error(err);
        process.exit(1);
    } 
}
// read urls from arguments provided to command
// ./script.js url1 url2 url3 ...
else{
    URL_TO_CHECK = [...options._]
}

// empty log file if option is set
if (options.log){
    fs.writeFileSync(options.log,'',(err) => console.error(err));
}

// check if array is empty
if ( !URL_TO_CHECK.length ){ 
    console.error("No arguments provided")
    yargs.showHelp()
    process.exit(1) 
}




// MAIN FUNCTION
// ----------------------------------------------------------------------------

async function get_formatted_url(){

    const browser = await puppeteer.launch({
        headless: false,
        executablePath: options.browser

    });
    const page = await browser.newPage();
    await page.setCacheEnabled(false);
    await page.setViewport({
        width: 1920,
        height: 1080
    })


    // MAIN FOR LOOP
    for( let index=0; index < URL_TO_CHECK.length; index++){

        // define current out file path: prepent sanitized output dir 
        page_content_path = options.outdir.replace(/\/$/,'') +"/"+ URL_TO_CHECK[index].replace(/\//g,":::");

        // define current url 
        if (options.prefix){
            // replace trailing and leading / on prefix and url resp.
            current_url = options.prefix.replace(/\/$/,'') +"/"+ URL_TO_CHECK[index].replace(/^\//,'');
        } else {
            current_url = URL_TO_CHECK[index] 
        }

        // start css coverage
        if (options.coverage){
            //coverage_report_path = options.outdir + url.replace(/\//g,":::") + ".coverage";
            coverage_report_path =  page_content_path + ".coverage";
            await page.coverage.startCSSCoverage();
        }

        // try to navigat to url, log error and continue
//        if (URL_TO_CHECK[index]) {

            try {
                await page.goto( current_url, {
                    waitUntil: 'networkidle2',
                    //timeout: 60000
                    timeout: 100000
                });
            }
            catch(err){
 //               console.error(err)
                CURRENT_STATUS = 1  
                console.log("ERROR url " + current_url + "  status  " + CURRENT_STATUS)
            }
        
        // condition on status here
        if (CURRENT_STATUS === 0){

// ---------------       
            // if element is set, click on it and wait 3 s
            if( options.element ){
                await page.evaluate((elem) => {

                    const button = document.querySelector(elem)
                    button ? button.click() : console.error("No cookie button")
                }, options.element)

                await page.waitForTimeout(3000);
            }

// ---------------       
            // scroll to bottom of page if option set
            if (options.scroll) {
                await page.evaluate( () => {
                    document.scrollingElement.scrollBy({
                        left: 0,
                        top: document.body.scrollHeight,
                        behavior: 'smooth'
                    })
                })
                await page.waitForTimeout(3000);
            }

// ---------------       
            // stop and write css coverage
            if( options.coverage ){
                css_coverage = await page.coverage.stopCSSCoverage();
                const tempArray = [];
                css_coverage.forEach( (val, index) => {
                    tempArray[index] = {url:val.url, ranges:val.ranges}
                })

                fs.writeFile( coverage_report_path, JSON.stringify( tempArray), err => {
                    if(err) {
                        console.error(err);
                        process.exit(1);
                    }
                })
            }
// ---------------       
            // write page content to file if option is set
            if ( options.write ){
                const html = await page.content();
                fs.writeFileSync( page_content_path, html);
            }
        } // end of status IF


// ------------- move to try catch
        // log success for that url if option is set 
        if ( options.log ){
            //fs.appendFile(options.log, "0    "+current_url+"\n", function (err) {
            fs.appendFileSync(
                options.log,
                `${CURRENT_STATUS}    ${current_url}\n`,
                (err) => console.error(err) )
        }
        
// ------------- reset for next loop iteration

        if (options.coverage && CURRENT_STATUS === 1){
            await page.coverage.stopCSSCoverage();

        }
        CURRENT_STATUS = 0;


    } // END OF MAIN FOR LOOP 


    await page.close();
    await browser.close();
}
get_formatted_url();

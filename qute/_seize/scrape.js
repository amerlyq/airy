// This script gets the latest full csv of one of my chase account.
//
// TODO Implement such for other chase accounts.

function clickAccountInfo (ms) {
   document.querySelector("#accountMaskLink-640332982").shadowRoot.querySelector("a > span.link__text").click();
   return new Promise(resolve => setTimeout(resolve, ms));
}

function clickDownload (ms) {
   document.querySelector("#downloadActivityIcon").shadowRoot.querySelector("button").click();
   return new Promise(resolve => setTimeout(resolve, ms));
}

function selectMenuDownload () {
   document.querySelector("#downloadActivityOptionId").shadowRoot.querySelector("#select-downloadActivityOptionId").click();
   document.querySelector("#downloadActivityOptionId > mds-select-option:nth-child(2)").shadowRoot.querySelector("div").click();
   document.querySelector("#download").shadowRoot.querySelector("button").click()
}

clickAccountInfo(15000).then( () => clickDownload(5000)).then( () => selectMenuDownload())

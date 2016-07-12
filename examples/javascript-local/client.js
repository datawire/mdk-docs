/* Run a HTTP client that looks up the location it should connect to using the
 * Datawire Microservices Development Kit (MDK).
 *
 * Make sure you have the DATAWIRE_TOKEN environment variable set with your
 * access control token.
 */


/* jshint node: true */

"use strict";

var process = require("process");
var args = process.argv.splice(process.execArgv.length + 2);

if (args.length == 0) {
    throw "usage: client service-name";
}

var service = args[0];

var request = require("request");

var MDK = require("datawire_mdk").mdk.init();
MDK.start()

function showResult(error, response, body) {
    var url = response.request.href;
    console.log(url + " => " + response.statusCode.toString() + ": " + body);
}


function loop() {
    var ssn = MDK.session();
    ssn.resolve_async(service, "1.0.0").then(function (node) {
        var url = node.address;

        ssn.info("client", "Connecting to " + url);
        var options = {
            url: url,
            headers: {
                "X-MDK-Context": ssn.inject(),
            }
        };
        request(options, showResult);
    });
}

setInterval(loop, 1000);

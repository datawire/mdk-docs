/* Run a HTTP server that registers its location using the Datawire
 * Microservices Development Kit (MDK).
 *
 * Make sure you have the DATAWIRE_TOKEN environment variable set with your
 * access control token.
 */

/* jshint node: true */

"use strict";

var process = require("process");
var args = process.argv.splice(process.execArgv.length + 2);

if (args.length === 0) {
    throw "usage: server service-name [port]";
}

var mdk = require("datawire_mdk").mdk;
var MDK = mdk.start();
process.on("beforeExit", function (code) {
    MDK.stop();
});

var host = "127.0.0.1";         // We are reachable only on localhost
var port = 5000;
var service = args[0];

if (args.length > 1) {
    port = parseInt(args[1]) || port;
}

MDK.register(service, "1.0.0", "http://" + host + ":" + port.toString());

var express = require("express");
var app = express();

app.get("/", function (req, res) {
    // Join the logging context from the request, if possible:
    var ssn = MDK.join(req.get(mdk.MDK.CONTEXT_HEADER));
    ssn.info(service, "Received a request.");
    res.send("Hello World (Node/Express)");
});

app.listen(port, host);

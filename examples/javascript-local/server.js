/* Run a HTTP server that registers its location using the Datawire
 * Microservices Development Kit (MDK).
 *
 * Make sure you have the DATAWIRE_TOKEN environment variable set with your
 * access control token.
 */

/* jshint node: true */

"use strict";

var process = require("process");
var express = require("express");
// MDK integration for express:
var mdk_express = require('datawire_mdk_express');

var args = process.argv.splice(process.execArgv.length + 2);
if (args.length === 0) {
    throw "usage: server service-name [port]";
}

var host = "127.0.0.1";         // We are reachable only on localhost
var port = 5000;
var service = args[0];
if (args.length > 1) {
    port = parseInt(args[1]) || port;
}

// Register with Datawire Discovery service:
mdk_express.mdk.register(service, "1.0.0", "http://" + host + ":" + port.toString());

var app = express();
// Hook up MDK to the Express application:
app.use(mdk_express.mdkSessionStart);

app.get("/", function (req, res) {
    // Log a message using the MDK session:
    req.mdk_session.info(service, "Received a request.");
    res.send("Hello World (Node/Express)");
});

app.listen(port, host);

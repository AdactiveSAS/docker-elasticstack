var http = require("http");

function requestHandler(options, callback) {
    var req = http.request(options, function (res) {
        var data = "";

        res.setEncoding('utf8');
        res.on('data', function (chunk) {
            data += chunk;
        });

        res.on('end', function () {
            if (res.statusCode !== 200) {
                console.error("Got status code " + res.statusCode + " with body: " + data);
                return;
            }

            var jsonData = null;
            try {
                jsonData = JSON.parse(data);

                callback(jsonData);
            } catch (e) {
                console.error(e.message);
                console.error("Got invalid JSON: " + data);
            }
        });

        res.on("error", function (e) {
            console.error("Got problem with response: " + e.message);
        });
    });

    req.on('error', function (e) {
        console.error("Got problem with request: " + e.message);
    });

    req.end();
}

function backupNow() {
    console.log("Start backupNow");

    var now = new Date();

    var options = {
        "method": "PUT",
        "host": "localhost",
        "port": 9200,
        "path": "_snapshot/s3_backup/" + formatDate(now) + "?wait_for_completion=true",
        "headers": {
            "Content-Type": "application/json"
        }
    };

    requestHandler(options, function (result) {
        if (result.snapshot.state !== "SUCCESS") {
            console.error("Got error with ELK: " + JSON.stringify(result));
            return;
        }

        console.log("Snapshot success: " + now.toISOString());
    });
}

function formatDate(date) {
    return encodeURIComponent(date.toISOString().toLowerCase());
}

backupNow();
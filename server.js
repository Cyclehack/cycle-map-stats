var application_root = __dirname,
	    express = require("express"),
	    path = require("path");

//Here we have initialized the express.js within javascript variables in respect of Node.js concept.
	var app = express();

//Here we have initialized the express web server in app variable.
	var databaseUrl = "testData";
	var collections = ["testData"];
	var mongojs = require('mongojs');
	var db = mongojs(databaseUrl, collections);

app.get('/', function (req, res) {
	    db.collection('testData').find(function(err, testData) { // Query in MongoDB via Mongo JS Module
	    if( err || !testData) console.log("No testData found");
	      else
	    {
	        res.writeHead(200, {'Content-Type': 'application/json'}); // Sending data via json
	        res.end(JSON.stringify(testData)); 
	    }
	  });
	});

app.listen(3000);
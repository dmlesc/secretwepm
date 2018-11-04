"use strict";

//Get-WebErrorEmails.ps1 
var spawn = require("child_process").spawn;

var PSpath = "C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe";
var scriptPath = "C:\\WindowsPowerShell\\PoSh\\Load\\";
//var interval = 10000;  //in ms = 1 second
var interval = 900000;  //in ms = 15 minutes
//How many minutes in a day?
var limit = (24 * 60) / 15; //the number of times it has to fail before alerting = 1 day
//var limit = 4; 
var failures = 0;

var running = false;

function scheduler() {
   var PSerr = "Error:\n\n";
   
   if (!running) {
      var child = spawn(PSpath, [scriptPath + "DeleteDeletedEmail.ps1"]);
      running = true;
      child.stdout.on("data", function(data) { console.log("PS: " + data); });
      child.stderr.on("data", function(data) {
         console.log("PSerr: " + data);
         PSerr += data;
      });
      child.on("exit", function(code) {
         running = false;
         
         if (!code) { 
            console.log("success");
            failures = 0;
         }
         else {
            console.log("failure");
            failures++;
            if (failures >= limit) {
               console.log(failures + " failures");
               sendEmail(PSerr);
            }
         }
      });
      child.stdin.end();
   }
   else { console.log("already running"); }
   
   setTimeout(scheduler, interval);
}

function sendEmail(PSerr) {
   var child = spawn(PSpath, [scriptPath + "SendEmail.ps1 -PSerr '" + PSerr + "'"]);
   child.stdout.on("data", function(data) { console.log("PS: " + data); });
   child.stderr.on("data", function(data) { console.log("PSerr: " + data); });
   child.on("exit", function(code) {
      if (!code) { console.log("email sent"); }
      else { console.log("email not sent"); }
   });
   child.stdin.end();
}

scheduler();
console.log("scheduler started");
"use strict";

function init() {
   var a = performance.now();

   var req = new XMLHttpRequest();
   var url = "status/status.json";
   req.onreadystatechange = function() {
      if (req.readyState == 4 && req.status == 200) {
         var status = JSON.parse(req.responseText);
         getID("itemsCount").innerHTML = "Unread Emails: " + status.itemsCount;
         getID("lastStarted").innerHTML = "Last Started: " + status.lastStarted;
         getID("lastEnded").innerHTML = "Last Ended: " + status.lastEnded;
         getID("currentStatus").innerHTML = "Current Status: " + status.currentStatus;

         var b = performance.now();
         console.log((b - a) + " ms");
      }
   };
   req.open("GET", url, true);
   req.send();
}

function getID(id) {
   return document.getElementById(id);
}
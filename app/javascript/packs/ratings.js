console.log("asd");
import LocalTime from "local-time"
LocalTime.start()

var Tablesort = require("tablesort")

document.addEventListener("turbolinks:load", function() {
  new Tablesort(document.getElementById('players_table'));
})

import "tablesort/tablesort"

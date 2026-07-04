// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

import LocalTime from "local-time"
LocalTime.start()

document.addEventListener("turbo:load", function() {
	if(document.getElementById('players_table')) {
		new Tablesort(document.getElementById('players_table'));
	}
	if(document.getElementById('stats_players_table')) {
		new Tablesort(document.getElementById('stats_players_table'), { descending: true });
	}
})

import "chartkick"
import "Chart.bundle"

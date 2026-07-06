// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

import LocalTime from "local-time"
LocalTime.start()

// "0:51" carry times and "87%" accuracies still compare as numbers.
function statValue(text) {
	text = (text || "").trim();
	const clock = text.match(/^(\d+):(\d{2})$/);
	if (clock) return parseInt(clock[1], 10) * 60 + parseInt(clock[2], 10);
	if (/^-?\d+(\.\d+)?%?$/.test(text)) return parseFloat(text);
	return NaN;
}

function boldColumnMaxima(table) {
	const rows = Array.from((table.tBodies[0] || {}).rows || []);
	if (rows.length < 2) return;
	const columns = table.tHead.rows[0].cells.length;
	for (let col = 1; col < columns; col++) {
		const cells = rows.map(row => row.cells[col]);
		// Only bold value cells: plain text, or markup that carries a
		// data-sort value (weighted pairs with <small> actuals). Name and
		// class cells have markup and no data-sort.
		if (cells.some(cell => !cell || (cell.children.length > 0 && cell.getAttribute("data-sort") === null))) continue;
		const values = cells.map(cell => {
			const sortValue = cell.getAttribute("data-sort");
			return statValue(sortValue !== null ? sortValue : cell.textContent);
		});
		const max = Math.max(...values.filter(value => !isNaN(value)));
		if (!isFinite(max) || max <= 0) continue;
		cells.forEach((cell, i) => {
			if (values[i] === max) cell.innerHTML = "<strong>" + cell.innerHTML + "</strong>";
		});
	}
}

document.addEventListener("turbo:load", function() {
	if(document.getElementById('players_table')) {
		new Tablesort(document.getElementById('players_table'));
	}
	document.querySelectorAll('table[data-sortable]').forEach(function(table) {
		new Tablesort(table, { descending: true });
	});
	document.querySelectorAll('table[data-bold-max]').forEach(boldColumnMaxima);
})

import "chartkick"
import "Chart.bundle"

document.addEventListener("alpine:init", async () => {
	Alpine.store("tilesets_loaded", false);

	let is_local = (new URL(location.href).port == "8000");
	let url_prefix;
	if (is_local) {
		url_prefix = "./data/";
	} else {
		url_prefix = "https://pub-02bff1796dd84d2d842f219d10ae945d.r2.dev/2023-04-01/";
	}

	let tilesets_raw = await fetch(`${url_prefix}tilesets.json`);
	tilesets_raw = await tilesets_raw.json();
	Alpine.store("tilesets", tilesets_raw);

	let tilesets = Alpine.store("tilesets");
				
	// add the PMTiles plugin to the maplibregl global.
	let protocol = new pmtiles.Protocol();
	maplibregl.addProtocol("pmtiles",protocol.tile);

	for( let i in tilesets.tilesets ) {
		let key = tilesets.tilesets[i].key;
		url = `${url_prefix}${key}.pmtiles`;
		tilesets.tilesets[i].url = url;

		var p = new pmtiles.PMTiles(url)
		// this is so we share one instance across the JS code and the map renderer
		protocol.add(p);
		tilesets.tilesets[i].pmtiles_obj = p;
	}

	let params = new URLSearchParams((location.hash ?? '#').substr(1));
	let len_filter = decodeFilterParams(params.get("len") ?? "")
	let selected_tileset_key = params.get("tiles") ?? tilesets.selected_tileset;
	Alpine.store("selected_tileset", selected_tileset_key);
	Alpine.store("tilesets_loaded", true);

	let sel = tilesets.tilesets.find(el => el.key === selected_tileset_key);
	console.assert(sel != undefined);

	map = new maplibregl.Map({
		container: 'map',
		zoom: 2,
		hash: "map",
		center: [0, 0],
		style: {
			version: 8,
			layers: mapstyle_layers,
			"glyphs": "./font/{fontstack}/{range}.pbf",
			sources: {
				"waterway": {
					type: "vector",
					url: "pmtiles://" + sel.url,
					attribution: '© <a href="https://openstreetmap.org">OpenStreetMap</a>'
				},
				"osmcarto": {
					type: "raster",
					tiles: ["https://tile.openstreetmap.org/{z}/{x}/{y}.png"],
					attribution: '© <a href="https://openstreetmap.org">OpenStreetMap</a>'
				},
			}
		}
	});
	// Add geolocate control to the map.
	map.addControl(
		new maplibregl.GeolocateControl({
			positionOptions: {
				enableHighAccuracy: true
			},
			trackUserLocation: true
		})
	);
	map.addControl(new maplibregl.NavigationControl());
	filterParamsChanged(len_filter);

	map.on("load", () => {
		let select = document.querySelector("#selected_tileset");
		select.addEventListener("change", (e) => {
			let new_key = e.target.value;
			console.assert(new_key != undefined);
			let selected_tileset = tilesets.tilesets.find(el => el.key == new_key);
			console.assert(selected_tileset != undefined);
			var loc = new URLSearchParams((location.hash ?? "#").substr(1));
			loc.set("tiles", new_key);
			location.hash = "#" +loc.toString();
			map.getSource("waterway").setUrl("pmtiles://" + selected_tileset.url);
		});
	});

});


function decodeFilterParams(s) {
	let filter_regex = /(?<min_filter>\d+(\.\d+)?)?(?<min_filter_unit>(m|km))?..(?<max_filter>\d+(\.\d+)?)?(?<max_filter_unit>(m|km))?/;
	let groups = s.match(filter_regex)?.groups ?? {};
	let min_filter_enabled = groups['min_filter'] != undefined;
	let max_filter_enabled = groups['max_filter'] != undefined;
	let min_filter = parseInt((groups.min_filter ?? "0"), 10);
	let max_filter = parseInt((groups.max_filter ?? "0"), 10);
	return {
		min_filter_enabled: min_filter_enabled, min_filter: min_filter, min_filter_unit: groups.min_filter_unit,
		max_filter_enabled: max_filter_enabled, max_filter: max_filter, max_filter_unit: groups.max_filter_unit
	};
}

function encodeFilterParams(min_filter_enabled, min_filter, min_filter_unit, max_filter_enabled, max_filter, max_filter_unit) {
	let result = "";
	if (min_filter_enabled) {
		result += `${min_filter}${min_filter_unit}`;
	}
	if (min_filter_enabled || max_filter_enabled) {
		result += ".."
	}
	if (max_filter_enabled) {
		result += `${max_filter}${max_filter_unit}`;
	}
	return result
}

function filterParamsChanged(len_filter) {
	let params = new URLSearchParams((location.hash ?? '#').substr(1));
	params.delete('min_len');
	params.delete('min_len_unit');
	params.delete('max_len');
	params.delete('max_len_unit');
	let encoded_len = encodeFilterParams(len_filter.min_filter_enabled, len_filter.min_filter, len_filter.min_filter_unit, len_filter.max_filter_enabled, len_filter.max_filter, len_filter.max_filter_unit);
	if (encoded_len == "") {
		params.delete('len');
	} else {
		params.set("len", encoded_len);
	}
	location.hash = '#' + params.toString();

	let new_filter = null;
	if (len_filter.min_filter_unit == 'm') {
		min_filter = parseInt(len_filter.min_filter, 10);
	} else if (len_filter.min_filter_unit == 'km' || len_filter.min_filter_unit == undefined) {
		min_filter = parseInt(len_filter.min_filter, 10)*1000;
	} else {
		console.error("unknown min_filter_unit: ", len_filter.min_filter_unit);
	}
	if (len_filter.max_filter_unit == 'm') {
		max_filter = parseInt(len_filter.max_filter, 10);
	} else if (len_filter.max_filter_unit == 'km' || len_filter.min_filter_unit == undefined) {
		max_filter = parseInt(len_filter.max_filter, 10)*1000;
	} else {
		console.error("unknown max_filter_unit: ", len_filter.max_filter_unit);
	}

	let min_filter_expr = ['>=', 'length_m', min_filter];
	let max_filter_expr = ['<=', 'length_m', max_filter];
	if (len_filter.min_filter_enabled && len_filter.max_filter_enabled) {
		new_filter = ['all', min_filter_expr, max_filter_expr];
	} else if (!len_filter.min_filter_enabled && len_filter.max_filter_enabled) {
		new_filter = max_filter_expr;
	} else if (len_filter.min_filter_enabled && !len_filter.max_filter_enabled) {
		new_filter = min_filter_expr;
	} else if (!len_filter.min_filter_enabled && !len_filter.max_filter_enabled) {
		new_filter = null;
	}

	if (map.loaded()) {
		map.setFilter('waterway-line-casing', new_filter);
		map.setFilter('waterway-line', new_filter);
		map.setFilter('waterway-text', new_filter);
	} else {
		map.once('load', () => {
			map.setFilter('waterway-line-casing', new_filter);
			map.setFilter('waterway-line', new_filter);
			map.setFilter('waterway-text', new_filter);
		});
	}
	// need some way to signify the filtering is done...
}

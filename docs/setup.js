document.addEventListener("alpine:init", async () => {
	Alpine.store("tilesets_loaded", false);
	let tilesets_raw = await fetch("tilesets.json");
	tilesets_raw = await tilesets_raw.json();
	Alpine.store("tilesets", tilesets_raw);
	Alpine.store("tilesets_loaded", true);

	let tilesets = Alpine.store("tilesets");
				
	// add the PMTiles plugin to the maplibregl global.
	let protocol = new pmtiles.Protocol();
	maplibregl.addProtocol("pmtiles",protocol.tile);
	let is_local = (new URL(location.href).port == "8000");

	for( let i in tilesets.tilesets ) {
		let key = tilesets.tilesets[i].key;
		if (is_local) {
			url = `./tiles/${key}.pmtiles`;
		} else {
			url = `https://pub-02bff1796dd84d2d842f219d10ae945d.r2.dev/2023-04-01/${key}.pmtiles`;
		}
		tilesets.tilesets[i].url = url;

		var p = new pmtiles.PMTiles(url)
		// this is so we share one instance across the JS code and the map renderer
		protocol.add(p);
		tilesets.tilesets[i].pmtiles_obj = p;
	}

	let params = new URLSearchParams((location.hash ?? '#').substr(1));
	min_filter_enabled = params.has('min_len');
	min_filter = params.get('min_len') ?? 0;
	min_filter_unit = params.get('min_len_unit') ?? "km";
	max_filter_enabled = params.has('max_len');
	max_filter = params.get('max_len') ?? 0;
	max_filter_unit = params.get('max_len_unit') ?? "km";
	selected_tileset_key = params.get("tiles") ?? tilesets.selected_tileset;

	console.debug(`Loading tiles ${selected_tileset_key}`);
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
	filterParamsChanged(min_filter_enabled, min_filter, min_filter_unit, max_filter_enabled, max_filter, max_filter_unit);

	map.on("load", () => {
		let radios = document.querySelectorAll("#layer_switchers input");
		for (let el of radios) {
			el.addEventListener("input", (e) => {
				let new_key = e.target.value;
				console.assert(new_key != undefined);
				let selected_tileset = tilesets.tilesets.find(el => el.key == new_key);
				console.assert(selected_tileset != undefined);
				var loc = new URLSearchParams((location.hash ?? "#").substr(1));
				loc.set("tiles", new_key);
				location.hash = "#" +loc.toString();
				map.getSource("waterway").setUrl("pmtiles://" + selected_tileset.url);
			});
		}
	});

});



function filterParamsChanged(min_filter_enabled, min_filter, min_filter_unit, max_filter_enabled, max_filter, max_filter_unit) {
	let params = new URLSearchParams((location.hash ?? '#').substr(1));
	if (min_filter_enabled) {
		params.set('min_len', min_filter);
		params.set('min_len_unit', min_filter_unit);
	} else {
		params.delete('min_len');
		params.delete('min_len_unit');
	}
	if (max_filter_enabled) {
		params.set('max_len', max_filter);
		params.set('max_len_unit', max_filter_unit);
	} else {
		params.delete('max_len');
		params.delete('max_len_unit');
	}
	location.hash = '#' + params.toString();

	let new_filter = null;
	if (min_filter_unit == 'm') {
		min_filter = parseInt(min_filter, 10);
	} else if (min_filter_unit == 'km') {
		min_filter = parseInt(min_filter, 10)*1000;
	} else {
		console.error("unknown min_filter_unit: ", min_filter_unit);
	}
	if (max_filter_unit == 'm') {
		max_filter = parseInt(max_filter, 10);
	} else if (max_filter_unit == 'km') {
		max_filter = parseInt(max_filter, 10)*1000;
	} else {
		console.error("unknown max_filter_unit: ", max_filter_unit);
	}

	let min_filter_expr = ['>=', 'length_m', min_filter];
	let max_filter_expr = ['<=', 'length_m', max_filter];
	if (min_filter_enabled && max_filter_enabled) {
		new_filter = ['and', min_filter_expr, max_filter_expr];
	} else if (!min_filter_enabled && max_filter_enabled) {
		new_filter = max_filter_expr;
	} else if (min_filter_enabled && !max_filter_enabled) {
		new_filter = min_filter_expr;
	} else if (!min_filter_enabled && !max_filter_enabled) {
		new_filter = null;
	}

	map.on('load', () => {
		map.setFilter('waterway-line-casing', new_filter);
		map.setFilter('waterway-line', new_filter);
		map.setFilter('waterway-text', new_filter);
	});
}

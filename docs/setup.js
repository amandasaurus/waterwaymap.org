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

	var selected_tileset_key = new URLSearchParams((location.hash ?? "#").substr(1)).get("tiles") ?? tilesets.selected_tileset;
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

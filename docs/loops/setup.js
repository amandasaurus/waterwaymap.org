document.addEventListener("alpine:init", async () => {
	Alpine.store("tilesets_loaded", false);

	let is_local = (new URL(location.href).port == "8000");
	let url_prefix;
	if (is_local) {
		url_prefix = `http://${location.host}/data/`;
	} else {
		url_prefix = "https://pub-02bff1796dd84d2d842f219d10ae945d.r2.dev/2023-04-01/";
	}

	let key = "planet-cycles"
	url = `${url_prefix}${key}.geojson`;

	Alpine.store("tilesets_loaded", true);

	map = new maplibregl.Map({
		container: 'map',
		zoom: 2,
		hash: "map",
		center: [0, 0],
		style: {
			version: 8,
			layers: mapstyle_layers,
			"glyphs": "/font/{fontstack}/{range}.pbf",
			sources: {
				"waterway": {
					type: "geojson",
					data: url,
					tolerance: 0,
				},
				"osmcarto": {
					type: "raster",
					tileSize: 256,
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

});

document.addEventListener("alpine:init", async () => {
	Alpine.store("tilesets_loaded", false);

	let is_local = (new URL(location.href).port == "8000");
	let url_prefix;
	if (is_local) {
		url_prefix = `http://${location.host}/data/`;
	} else {
		url_prefix = "https://pub-02bff1796dd84d2d842f219d10ae945d.r2.dev/2023-04-01/";
	}

	// add the PMTiles plugin to the maplibregl global.
	let protocol = new pmtiles.Protocol();
	maplibregl.addProtocol("pmtiles", protocol.tile);

	let key = "planet-ends"
	url = `${url_prefix}${key}.pmtiles`;

	var p = new pmtiles.PMTiles(url)
	// this is so we share one instance across the JS code and the map renderer
	protocol.add(p);


	Alpine.store("tilesets_loaded", true);

	map = new maplibregl.Map({
		container: 'map',
		zoom: 2,
		hash: "map",
		center: [0, 0],
		style: {
			version: 8,
			layers: [
				{
					"id": "osmcarto",
					"type": "raster",
					"source": "osmcarto",
				},
				{
					"id":"ends",
					"source": "ends",
					"source-layer":"ends",
					"type": "circle",
					"paint": {
						"circle-color": "red",
						"circle-radius": ["interpolate", ["linear"], ["get", "upstream_m"], 0, 0, 10*1000, 1, 1000*1000, 10]
					}
				},
				{
					"id":"ends-text",
					"source": "ends",
					"source-layer":"ends",
					"type": "symbol",
					"paint": {
						"text-color": "red",
					},
					"filter": [">", ["get", "upstream_m"], 10*1000],
					"layout": {
						"text-font": [ "Open Sans Semibold" ],
						"text-field": ["concat", ["round", ["/", ["get", "upstream_m"], 1000]], " km"],
						"text-offset": [0, 1],
						"text-size": ["interpolate", ["linear"], ["get", "upstream_m"], 0, 0, 1000*1000, 15]
					}
				}
			],
			"glyphs": "/font/{fontstack}/{range}.pbf",
			sources: {
				"ends": {
					type: "vector",
					url: "pmtiles://" + url,
					attribution: '© <a href="https://openstreetmap.org">OpenStreetMap</a>'
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

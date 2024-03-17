document.addEventListener("alpine:init", async () => {
  Alpine.store("tilesets_loaded", false);

  let is_local = new URL(location.href).port == "8000";
  let url_prefix;
  if (is_local) {
    url_prefix = `http://${location.host}/data/`;
  } else {
    url_prefix = "https://data.waterwaymap.org/";
  }

  // add the PMTiles plugin to the maplibregl global.
  let protocol = new pmtiles.Protocol();
  maplibregl.addProtocol("pmtiles", protocol.tile);

  let key = "planet-ends";
  url = `${url_prefix}${key}.pmtiles`;

  var p = new pmtiles.PMTiles(url);
  // this is so we share one instance across the JS code and the map renderer
  protocol.add(p);

  Alpine.store("tilesets_loaded", true);

  map = new maplibregl.Map({
    container: "map",
    zoom: 2,
    hash: "map",
    center: [0, 0],
    style: {
      version: 8,
      layers: [
        {
          id: "osmcarto",
          type: "raster",
          source: "osmcarto",
        },
        {
          id: "ends",
          source: "ends",
          "source-layer": "ends",
          type: "circle",
          paint: {
            "circle-color": "black",
            "circle-radius": [
              "interpolate",
              ["linear"],
              ["get", "upstream_m"],
              0,
              0,
              10 * 1000,
              1,
              100 * 1000,
              2,
              1000 * 1000,
              10,
            ],
          },
        },
        {
          id: "ends-text",
          source: "ends",
          "source-layer": "ends",
          type: "symbol",
          paint: {
            "text-color": "black",
          },
          filter: [">", ["get", "upstream_m"], 50 * 1000],
          layout: {
            "text-font": ["Open Sans Semibold"],
            "text-field": [
              "concat",
              ["round", ["/", ["get", "upstream_m"], 1000]],
              " km",
            ],
            "text-offset": [0, 1],
            "text-size": [
              "interpolate",
              ["linear"],
              ["get", "upstream_m"],
              0,
              0,
              50 * 1000,
              10,
              1000 * 1000,
              15,
            ],
          },
        },
      ],
      glyphs: "/font/{fontstack}/{range}.pbf",
      sources: {
        ends: {
          type: "vector",
          url: "pmtiles://" + url,
          attribution:
            '© <a href="https://openstreetmap.org">OpenStreetMap</a>',
        },
        osmcarto: {
          type: "raster",
          tileSize: 256,
          tiles: ["https://tile.openstreetmap.org/{z}/{x}/{y}.png"],
          attribution:
            '© <a href="https://openstreetmap.org">OpenStreetMap</a>',
        },
      },
    },
  });
  // Add geolocate control to the map.
  map.addControl(
    new maplibregl.GeolocateControl({
      positionOptions: {
        enableHighAccuracy: true,
      },
      trackUserLocation: true,
    }),
  );
  map.addControl(new maplibregl.NavigationControl());

  map.on("mousemove", (e) => {
    const features = map.queryRenderedFeatures(e.point);
    if (features.length == 0) {
      return;
    }
    const props = features[0].properties;

    document.getElementById("hover_results").innerHTML =
      `<a href="https://www.openstreetmap.org/node/${props.nid}/" target="_blank">Node ${props.nid}</a> (<a href="http://localhost:8111/load_object?objects=n${props.nid}&referrers=true" target=_blank>josm</a>) has ${Math.round(props.upstream_m / 1000.0)} km of upstreams and ends here.`;
  });
});

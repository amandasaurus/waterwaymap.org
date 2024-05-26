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

  let key = "planet-loops";
  url = `${url_prefix}${key}.pmtiles`;

  var p = new pmtiles.PMTiles(url);
  // this is so we share one instance across the JS code and the map renderer
  protocol.add(p);

  tilesToLoad = new Set();
  function loadingEffect(e) {
    if (e.sourceId == "loops" && e?.tile) {
      (e.type == "dataloading" ? tilesToLoad.add : tilesToLoad.delete)(
        e.tile.uid,
      );
      map.setPaintProperty(
        "loops",
        "line-color",
        tilesToLoad.size == 0 ? "black" : "red",
      );
    }
  }

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
          id: "loops-points",
          source: "loops",
          "source-layer": "loop_points",
          type: "circle",
          paint: {
            "circle-radius": ["interpolate", ["linear"], ["zoom"], 0, 2, 3, 3, 6, 4, 12, 3, 19, 5]
          },
        },
        {
          id: "loops-points-halo",
          source: "loops",
          "source-layer": "loop_points",
          type: "circle",
          paint: {
            "circle-radius": ["interpolate", ["linear"], ["zoom"], 0, 10, 12, 10, 15, 0],
            "circle-blur": 2,
          },
        },
        {
          id: "loops",
          source: "loops",
          "source-layer": "loop_lines",
          type: "line",
          paint: {
            "line-color": "black",
            "line-width": ["interpolate", ["linear"], ["zoom"], 0, 10, 15, 3],
          },
          layout: {
            "line-cap": "round",
            "line-join": "round",
          },
        },
      ],
      glyphs: "/font/{fontstack}/{range}.pbf",
      sources: {
        loops: {
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
  map.on("dataloading", loadingEffect);
  map.on("data", loadingEffect);
  map.on("dataabort", loadingEffect);

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
});

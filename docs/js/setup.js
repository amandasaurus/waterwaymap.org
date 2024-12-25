document.addEventListener("alpine:init", async () => {
  Alpine.store("tilesets_loaded", false);

  let is_local = new URL(location.href).port == "8000";
  let url_prefix;
  if (is_local) {
    url_prefix = "./data/";
  } else {
    url_prefix = "https://data.waterwaymap.org/";
  }

  let tilesets_raw = await fetch(`${url_prefix}tilesets.json`);
  tilesets_raw = await tilesets_raw.json();
  Alpine.store("tilesets", tilesets_raw);

  let tilesets = Alpine.store("tilesets");

  // add the PMTiles plugin to the maplibregl global.
  let protocol = new pmtiles.Protocol();
  maplibregl.addProtocol("pmtiles", protocol.tile);

  for (let i in tilesets.tilesets) {
    let key = tilesets.tilesets[i].key;
    url = `${url_prefix}${key}.pmtiles`;
    if (tilesets.tilesets[i].frames ?? false) {
      url = `${url_prefix}${key}-w_frames.pmtiles`;
    } else {
      url = `${url_prefix}${key}.pmtiles`;
    }
    tilesets.tilesets[i].url = url;

    var p = new pmtiles.PMTiles(url);
    // this is so we share one instance across the JS code and the map renderer
    protocol.add(p);
    tilesets.tilesets[i].pmtiles_obj = p;

  }

  let params = new URLSearchParams((location.hash ?? "#").substr(1));
  let len_filter = decodeFilterParams(params.get("len") ?? "");
  let show_frames = (params.get("frames") ?? "no") == "yes";
  let selected_tileset_key = params.get("tiles") ?? tilesets.selected_tileset;
  if (!tilesets.tilesets.map(t => t.key).some(t => selected_tileset_key == t)) {
    console.error(
      "The selected tileset " +
        selected_tileset_key +
        " doesn't exist, using default of " +
        tilesets.selected_tileset +
        " instead.",
    );
    selected_tileset_key = tilesets.selected_tileset;
  }
  Alpine.store("selected_tileset", selected_tileset_key);
  Alpine.store("tilesets_loaded", true);

  let sel = tilesets.tilesets.find((el) => el.key === selected_tileset_key);
  console.assert(sel != undefined);

  map = new maplibregl.Map({
    container: "map",
    zoom: 2,
    hash: "map",
    center: [0, 0],
    attributionControl: false,  // manually added later (w. date)
    style: {
      version: 8,
      layers: mapstyle_layers,
      glyphs: "./font/{fontstack}/{range}.pbf",
      sources: {
        waterway: {
          type: "vector",
          url: "pmtiles://" + sel.url,
          attribution:
            '<a href="https://www.openstreetmap.org/copyright">© OpenStreetMap contributors</a>',
        },
        osmcarto: {
          type: "raster",
          tiles: ["https://tile.openstreetmap.org/{z}/{x}/{y}.png"],
          tileSize: 256,
          attribution:
            '<a href="https://www.openstreetmap.org/copyright">© OpenStreetMap contributors</a>',
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
  map.addControl(new maplibregl.AttributionControl({customAttribution: "Data as of "+tilesets.data_timestamp}));
  filterParamsChanged(len_filter);

  map.setPadding({ top: 57 });

  var scale = new maplibregl.ScaleControl({
    maxWidth: 200,
    unit: "metric",
  });
  map.addControl(scale);
  
  map.dragRotate.disable();
  map.touchZoomRotate.disableRotation();
  
  map.on("load", () => {
    let select = document.querySelector("#selected_tileset");
    select.addEventListener("change", (e) => {
      let new_key = e.target.value;
      console.assert(new_key != undefined);
      let selected_tileset = tilesets.tilesets.find((el) => el.key == new_key);
      console.assert(selected_tileset != undefined);
      var loc = new URLSearchParams((location.hash ?? "#").substr(1));
      loc.set("tiles", new_key);
      location.hash = "#" + loc.toString();
      map.getSource("waterway").setUrl("pmtiles://" + selected_tileset.url);
    });
    var params = new URLSearchParams((location.hash ?? "#").substr(1));
    let show_frames = (params.get("frames") ?? "no") == "yes";
    map.getLayer('waterway-frames-line').setLayoutProperty('visibility', (show_frames?'visible':'none'));
  });
});

function decodeFilterParams(s) {
  let filter_regex = /(?<min_filter>\d+)?\.\.(?<max_filter>\d+)?/;
  let groups = s.match(filter_regex)?.groups ?? {};
  let min_filter_enabled = (groups["min_filter"] ?? "0") != "0";
  let max_filter_enabled = (groups["max_filter"] ?? "inf") != "inf";
  let min_filter = parseInt(groups.min_filter ?? "0", 10);
  let max_filter;
  if ((groups["max_filter"] ?? "inf") == "inf") {
    max_filter = null;
  } else {
    max_filter = parseInt(groups.max_filter ?? "0", 10);
  }
  return {
    min_filter_enabled: min_filter_enabled,
    min_filter: min_filter,
    max_filter_enabled: max_filter_enabled,
    max_filter: max_filter,
  };
}

function encodeFilterParams(
  min_filter_enabled,
  min_filter,
  max_filter_enabled,
  max_filter,
) {
  let result = "";
  if (!min_filter_enabled && !max_filter_enabled) {
    return "";
  }
  if (min_filter_enabled) {
    result += `${min_filter}`;
  } else {
    result += "0";
  }

  if (min_filter_enabled || max_filter_enabled) {
    result += "..";
  }
  if (max_filter_enabled) {
    result += `${max_filter}`;
  } else {
    result += "inf";
  }
  return result;
}

function filterParamsChanged(len_filter) {
  let params = new URLSearchParams((location.hash ?? "#").substr(1));
  params.delete("min_len");
  params.delete("min_len_unit");
  params.delete("max_len");
  params.delete("max_len_unit");
  let encoded_len = encodeFilterParams(
    len_filter.min_filter_enabled,
    len_filter.min_filter,
    len_filter.max_filter_enabled,
    len_filter.max_filter,
  );
  if (encoded_len == "") {
    params.delete("len");
  } else {
    params.set("len", encoded_len);
  }
  location.hash = "#" + params.toString();

  let new_filter = null;
  let new_filter_up = null;
  min_filter = parseInt(len_filter.min_filter, 10) * 1000;
  max_filter = parseInt(len_filter.max_filter, 10) * 1000;

  // TODO duplicate with upstreams having different attrs. Can we rename the
  // attrs in tippecanoe?

  let min_filter_expr = [">=", "length_m", min_filter];
  let min_filter_expr_up = [">=", "avg_upstream_m", min_filter];
  let max_filter_expr = ["<=", "length_m", max_filter];
  let max_filter_expr_up = ["<=", "avg_upstream_m", max_filter];
  if (len_filter.min_filter_enabled && len_filter.max_filter_enabled) {
    new_filter = ["all", min_filter_expr, max_filter_expr];
    new_filter_up = ["all", min_filter_expr_up, max_filter_expr_up];
  } else if (!len_filter.min_filter_enabled && len_filter.max_filter_enabled) {
    new_filter = max_filter_expr;
    new_filter_up = max_filter_expr_up;
  } else if (len_filter.min_filter_enabled && !len_filter.max_filter_enabled) {
    new_filter = min_filter_expr;
    new_filter_up = min_filter_expr_up;
  } else if (!len_filter.min_filter_enabled && !len_filter.max_filter_enabled) {
    new_filter = null;
    new_filter_up = null;
  }

  if (map.loaded()) {
    map.setFilter("waterway-line-casing", new_filter);
    map.setFilter("waterway-line", new_filter);
    map.setFilter("waterway-text-length", new_filter);
    map.setFilter("waterway-text-wayid", new_filter);
    map.setFilter("waterway-frames-line", new_filter);
    map.setFilter("upstream-line", new_filter_up);
    map.setFilter("upstream-line-casing", new_filter_up);
    map.setFilter("upstream-text-length", new_filter_up);
    map.setFilter("upstream-text-wayid", new_filter_up);
  } else {
    map.once("load", () => {
      map.setFilter("waterway-line-casing", new_filter);
      map.setFilter("waterway-line", new_filter);
      map.setFilter("waterway-text-length", new_filter);
      map.setFilter("waterway-text-wayid", new_filter);
      map.setFilter("waterway-frames-line", new_filter);
      map.setFilter("upstream-line", new_filter_up);
      map.setFilter("upstream-line-casing", new_filter_up);
      map.setFilter("upstream-text-length", new_filter_up);
      map.setFilter("upstream-text-wayid", new_filter_up);
    });
  }
  // need some way to signify the filtering is done...
}

function changeMapColours(num) {
  if ([2, 3, 4, 5, 6, 7].includes(num)) {
    map.setPaintProperty('waterway-line', 'line-color', ['match', ['%', ['get', 'root_nodeid_120'], num], 0, '#a6cee3', 1, '#1f78b4', 2, '#33a02c', 3, '#fb9a99', 4, '#e31a1c', 5, '#fdbf6f', 6, '#ff7f00', 7, '#cab2d6', 'black' ]);
    map.setPaintProperty('upstream-line', 'line-color', ['match', ['%', ['get', 'end_nid'], num], 0, '#a6cee3', 1, '#1f78b4', 2, '#33a02c', 3, '#fb9a99', 4, '#e31a1c', 5, '#fdbf6f', 6, '#ff7f00', 7, '#cab2d6', 'black' ]);
  } else if (num == 11) {
    map.setPaintProperty('waterway-line', 'line-color', ['match',['%', ['get', 'root_nodeid_120'], 11],0, '#71f671',1, '#fafa76',2, '#5e5ef5',3, '#cb3d55',4, '#723acb',5, '#00ac84',6, '#b77231',7, '#80c4c4',8, '#f58c5e',9, '#9e1e9e',10, '#429c42','black',])
    map.setPaintProperty('upstream-line', 'line-color', ['match',['%', ['get', 'end_nid'], 11],0, '#71f671',1, '#fafa76',2, '#5e5ef5',3, '#cb3d55',4, '#723acb',5, '#00ac84',6, '#b77231',7, '#80c4c4',8, '#f58c5e',9, '#9e1e9e',10, '#429c42','black',])
  } else if (num == 24) {
    map.setPaintProperty('waterway-line', 'line-color', ['match',['%', ['get', 'root_nodeid_120'], 24],
      0, '#fd5500',    1, '#ffa700',   2, '#feec00',   3, '#b1ff00',   4, '#06fe59',   5, '#03ffef',
      6, '#0071ff',    7, '#2a00ff',   8, '#9501ff',   9, '#ff03ff',  10, '#ff026a',  11, '#ff0102',
      12, '#973401',  13, '#986500',  14, '#998d00',  15, '#6c9900',  16, '#019937',  17, '#009b8f',
      18, '#01439a',  19, '#180098',  20, '#590197',  21, '#99009a',  22, '#99003f',  23, '#970101',
      'black', ])
    map.setPaintProperty('upstream-line', 'line-color', ['match',['%', ['get', 'end_nid'], 24],
      0, '#fd5500',    1, '#ffa700',   2, '#feec00',   3, '#b1ff00',   4, '#06fe59',   5, '#03ffef',
      6, '#0071ff',    7, '#2a00ff',   8, '#9501ff',   9, '#ff03ff',  10, '#ff026a',  11, '#ff0102',
      12, '#973401',  13, '#986500',  14, '#998d00',  15, '#6c9900',  16, '#019937',  17, '#009b8f',
      18, '#01439a',  19, '#180098',  20, '#590197',  21, '#99009a',  22, '#99003f',  23, '#970101',
      'black', ])
  }
}

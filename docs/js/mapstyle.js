var mapstyle_layers = [
  {
    id: "osmcarto",
    type: "raster",
    source: "osmcarto",
  },
  {
    id: "waterway-line-casing",
    source: "waterway",
    "source-layer": "waterway",
    type: "line",
    paint: {
      "line-color": "black",
      "line-width": [
        "interpolate",
        ["linear"], ["zoom"],
        0, 1.1, 4, 1.1, 6, 2.2, 7, 5,
      ],
    },
    layout: {
      "line-cap": "round",
      "line-join": "round",
    },
  },
  {
    id: "waterway-line",
    source: "waterway",
    "source-layer": "waterway",
    type: "line",
    layout: {
      "line-cap": "round",
      "line-join": "round",
    },
    paint: {
      "line-color": [
        "match",
        ["%", ["get", "root_nodeid_120"], 7],
        0, "#a6cee3",
        1, "#1f78b4",
        2, "#33a02c",
        3, "#fb9a99",
        4, "#e31a1c",
        5, "#fdbf6f",
        6, "#ff7f00",
        7, "#cab2d6",
        "black",
      ],
      "line-width": [
        "interpolate",
        ["linear"], ["zoom"],
        0, 1,  4, 1,  6, 2,  7, 3,  15, 3,  20, 5,
      ],
    },
  },
  {
    id: "waterway-text-length",
    source: "waterway",
    "source-layer": "waterway",
    type: "symbol",
    paint: {
      "text-color": "blue",
    },
    layout: {
      "text-font": ["Open Sans Semibold"],
      "text-field": [ "concat", ["round", ["/", ["get", "length_m"], 1000]], " km", ],
      "text-offset": [0, 1],
      "symbol-placement": "line",
    },
  },
  {
    id: "waterway-text-wayid",
    source: "waterway",
    "source-layer": "waterway",
    type: "symbol",
    minzoom: 18,
    paint: {
      "text-color": "blueviolet",
    },
    layout: {
      "text-font": ["Open Sans Semibold"],
      "text-field": [ "concat", "id: ", ["coalesce", ["get", "root_nodeid"], "N/A" ] ],
      "text-offset": [0, -1],
      "symbol-placement": "line",
    },
  },
  {
    id: "waterway-frames-line",
    source: "waterway",
    "source-layer": "frames",
    type: "line",
    layout: {
      "line-cap": "butt",
      "line-join": "round",
      "visibility": "none",
    },
    paint: {
      "line-color": "black",
      "line-width": 4,
      "line-gap-width": ["interpolate", ["linear"], ["zoom"], 0, 0, 6, 0, 12, 9],
    },
  },

  {
    "id": "upstream-line-casing",
    "type": "line",
    "source": "waterway",
    "source-layer": "upstreams",
    "layout": {
      "line-cap": "round",
      "line-join": "round",
    },
    "paint": {
      "line-color": "black",
      "line-width": ["interpolate", ["linear"], ["zoom"],
        0, ["interpolate", ["linear"], ["get", "avg_upstream_m"], 0,0, 6e6,7],
        4, ["interpolate", ["linear"], ["get", "avg_upstream_m"], 0,0, 6e6,7],
        6, ["interpolate", ["linear"], ["get", "avg_upstream_m"], 0,0, 6e6,11],
        12, ["interpolate", ["linear"], ["get", "avg_upstream_m"], 0,0, 1e3,1.5, 50e3,8, 6e6,18],
      ]
    }
  },
  {
    "id": "upstream-line",
    "type": "line",
    "source": "waterway",
    "source-layer": "upstreams",
    "layout": {
      "line-cap": "round",
      "line-join": "round",
    },
    "paint": {
      "line-color": [
        "match",
        ["%", ["get", "end_nid"], 7],
        0, "#a6cee3",
        1, "#1f78b4",
        2, "#33a02c",
        3, "#fb9a99",
        4, "#e31a1c",
        5, "#fdbf6f",
        6, "#ff7f00",
        7, "#cab2d6",
        "black",
      ],
      "line-width": ["interpolate", ["linear"], ["zoom"],
        0, ["interpolate", ["linear"], ["get", "avg_upstream_m"], 0,0, 6e6,4],
        4, ["interpolate", ["linear"], ["get", "avg_upstream_m"], 0,0, 6e6,4],
        6, ["interpolate", ["linear"], ["get", "avg_upstream_m"], 0,0, 6e6,9],
        12, ["interpolate", ["linear"], ["get", "avg_upstream_m"], 0,0, 1e3,1, 50e3,5, 6e6,10],
        //16, ["interpolate", ["linear"], ["get", "avg_upstream_m"], 0,0, 50e3,8, 6e6,20],
      ]
    }
  },
  
  {
    id: "upstream-text-length",
    source: "waterway",
    "source-layer": "upstreams",
    type: "symbol",
    paint: {
      "text-color": "blue",
    },
    layout: {
      "text-font": ["Open Sans Semibold"],
      "text-field": [ "concat", ["round", ["/", ["get", "avg_upstream_m"], 1000]], " km", ],
      "text-offset": [0, 2],
      "symbol-placement": "line",
      "text-max-angle": 20,
    },
  },
  {
    id: "upstream-text-wayid",
    source: "waterway",
    "source-layer": "upstreams",
    type: "symbol",
    minzoom: 17,
    paint: {
      "text-color": "blueviolet",
      "text-opacity": 0.,
    },
    layout: {
      "text-font": ["Open Sans Semibold"],
      "text-field": [ "concat", "end total :", ["round", ["/", ["get", "end_upstream_m"], 1000]], " km" ],
      "text-offset": [0, -2],
      "symbol-placement": "line",
    },
  },
];

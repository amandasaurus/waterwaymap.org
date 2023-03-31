var mapstyle_layers = [
	{
		"id": "osmcarto",
		"type": "raster",
		"source": "osmcarto",
	},
	{
		"id":"waterway-line-casing",
		"source": "waterway",
		"source-layer":"waterway",
		"type": "line",
		"paint": {
			"line-color":  "black",
			"line-width": ["interpolate", ["linear"], ["zoom"], 0, 0, 4.99, 0, 5, 1.2, 6, 4, 7, 5],
		},
		"layout": {
			"line-cap":  "round",
			"line-join":  "round",
		}
	},
	{
		"id":"waterway-line",
		"source": "waterway",
		"source-layer":"waterway",
		"type": "line",
		"layout": {
			"line-cap":  "round",
			"line-join":  "round",
		},
		"paint": {
			"line-color":  ["match",
				["%", ["get", "root_wayid"], 8],
				0, '#a6cee3',
				1, '#1f78b4',
				2, '#b2df8a',
				3, '#33a02c',
				4, '#fb9a99',
				5, '#e31a1c',
				6, '#fdbf6f',
				7, '#ff7f00',
				8, '#cab2d6',
				'black',
			],
			"line-width": ["interpolate", ["linear"], ["zoom"], 0, 1, 6, 1, 7, 3, 15, 3, 20, 5],
		}
	},
	{
		"id":"waterway-text",
		"source": "waterway",
		"source-layer":"waterway",
		"type": "symbol",
		"paint": {
			"text-color": "blue",
		},
		"layout": {
			"text-font": [ "Open Sans Semibold" ],
			"text-field": ["concat", ["round", ["/", ["get", "length_m"], 1000]], " km"],
			"text-offset": [0, 1],
			"symbol-placement": "line",
		}
	}
];

# [WaterwayMap.org](https://waterwaymap.org)

See the [website](https://waterwaymap.org).

![map of europe with all the river basins higlighted](https://waterwaymap.org/img/screenshot.png)

[News & Updates on the OSM Town Mapstodon](https://en.osm.town/@amapanda/tagged/WaterwayMapOrg).

## News & Posts

* [Fedi/Mastodon post](https://en.osm.town/@amapanda/110118513232919061)
* [OSM Community Forum](https://community.openstreetmap.org/t/osm-river-basins-website-to-show-how-are-rivers-in-osm-connected/102655)
* Hacker News: [#1 (2023-08-30) (as “OSM River Basins”)](https://news.ycombinator.com/item?id=37321292), [#2 (2024-01-24)](https://news.ycombinator.com/item?id=39110434), [#3 (2024-08-19)](https://news.ycombinator.com/item?id=41293757)
* I gave a lightening talk at [State of the Map Europe 2023](https://2023.stateofthemap.eu/) in Antwerp, Belgium in Nov. 2023. [slides](https://waterwaymap.org/static/2023-11-sotmeu23-waterway-presentation-lightening-talk.pdf.zst).
* *“Flowing Connections: Mapping rivers & streams with WaterwayMap.org”* Presentation at [State of the Map Europe 2024](https://stateofthemap.eu/) in Łódź, Poland on Sun. 21st July 2024. [slides](https://waterwaymap.org/static/2024-07-21-sotmeu24-waterway-presentation.pdf.zst). [programme entry](https://cfp.openstreetmap.org.pl/state-of-the-map-europe-2024/talk/K8LF7U/). As of Jan. 2025, there are no recordings available.
* [Interview about WaterwayMap.org on The OpenCage Blog](https://blog.opencagedata.com/post/openstreetmap-interview-waterwaymap) _(Jan. 2025)_

## Who's using mapping with this?

* [neis-one `#WaterwayMapOrg`](https://resultmaps.neis-one.org/osm-changesets?comment=WaterwayMapOrg) (older [`#RiverMapping` tag](https://resultmaps.neis-one.org/osm-changesets?comment=RiverMapping)).
* [OSMCha `#WaterwayMapOrg`](https://osmcha.org/?filters=%7B%22metadata%22%3A%5B%7B%22label%22%3A%22hashtags%3D%23WaterwayMapOrg%22%2C%22value%22%3A%22hashtags%3D%23WaterwayMapOrg%22%7D%5D%7D) (_older [`#RiverMapping` on OSMCha](https://osmcha.org/?filters=%7B%22metadata%22%3A%5B%7B%22label%22%3A%22hashtags%3D%23RiverMapping%22%2C%22value%22%3A%22hashtags%3D%23RiverMapping%22%7D%5D%7D)_)

### OSM Tagging Discussions from this tool

* [Should river lines be mapped through lakes, estuaries, gulfs, and other large water bodies?](https://community.openstreetmap.org/t/should-river-lines-be-mapped-through-lakes-estuaries-gulfs-and-other-large-water-bodies/104438) _(Oct. 2023)_
  * [Flowlines](https://wiki.openstreetmap.org/wiki/Proposal:Flowlines) tagging proposal. [osm comm. forum](https://community.openstreetmap.org/t/rfc-feature-proposal-flowlines/117361) & [`tagging@`](https://lists.openstreetmap.org/pipermail/tagging/2024-August/067978.html).
* [Properly mapping dry washes](https://community.openstreetmap.org/t/properly-mapping-dry-washes/108437) _(Jan. 2024)_
* [Is there a common tag for underground infiltrated watercourses?](https://community.openstreetmap.org/t/is-there-a-common-tag-for-underground-infiltrated-watercourses/111558) _(Apr. 2024)_
* [How to map a Lazy river in an amusement park](https://community.openstreetmap.org/t/how-to-map-a-lazy-river-in-an-amusement-park/113429) _(May 2024)_
* [RfC: Deprecate use of “waterway=pressurised” on anything not artificially built for hydropower uses](https://community.openstreetmap.org/t/rfc-deprecate-use-of-waterway-pressurised-on-anything-not-artificially-built-for-hydropower-uses/115222) _(June 2024)_
* All posts [tagged `#waterwaymaporg`](https://community.openstreetmap.org/tag/waterwaymaporg), or [`#waterway`](https://community.openstreetmap.org/tag/waterway) on the OSM Community Forum.

## Loops

Loops in waterways are detected and shown on:
[`WaterwayMap.org/loops`](https://waterwaymap.org/loops).


* [Fedi/Masto post](https://en.osm.town/@amapanda/111658136395447174)
* [OSM Ccommunity Forum announcement](https://community.openstreetmap.org/t/the-wonders-of-early-medieval-fore-abbey-and-osm-river-topology-today-i-e-waterwaymap-org-is-going-around-in-circles/107497)


## End Points

Points at which waterways end are shown on: [`WaterwayMap.org/ends`](https://waterwaymap.org/ends).

* [Fedi/Masto post](https://en.osm.town/@amapanda/111844170704856219)
* [OSM Ccommunity Forum announcement](https://community.openstreetmap.org/t/the-end-of-waterway-map/108632)

### Where things turn into streams

To detect places where waterways (e.g. rivers) flow into a stream, a GeoJSON file of those is generated: [`data.waterwaymap.org/planet-waterway-stream-ends.geojson.gz`](https://data.waterwaymap.org/planet-waterway-stream-ends.geojson.gz) (~ 2 MiB compressed). It can be loaded into JOSM to find errors.

It was asked for in [issue 52](https://github.com/amandasaurus/waterwaymap.org/issues/52), with the code in [commit `4730275`](https://github.com/amandasaurus/waterwaymap.org/commit/4730275509c1655e46a09c3994436403b3bd5ec1).

## Statistics

### Loops

A CSV file of statistics of loops is generated and available for download at
[`data.waterwaymap.org/waterwaymap.org_loops_stats.csv`](
https://data.waterwaymap.org/waterwaymap.org_loops_stats.csv). See the
[`osm-lump-ways` documentation on the CSV stats
file](https://github.com/amandasaurus/osm-lump-ways?tab=readme-ov-file#ends-stats-csv---ends-csv-file-filenamecsv)
for documentation.

It is used by [`@watmildon@en.osm.town`](https://en.osm.town/@watmildon) for a
mastodon account summarizing stats:
[`@OSMWaterwayLoopStats@en.osm.town`](https://en.osm.town/@OSMWaterwayLoopStats)
[feed](https://en.osm.town/@OSMWaterwayLoopStats.rss)

### End Points

A CSV statistics file of end points, is also generated dails and downloadable at
[`data.waterwaymap.org/waterwaymap.org_ends_stats.csv.zst`](https://data.waterwaymap.org/waterwaymap.org_ends_stats.csv.zst).

See the [`osm-lump-ways`
documentation](https://github.com/amandasaurus/osm-lump-ways?tab=readme-ov-file#ends-stats-csv---ends-csv-file-filenamecsv)
for file format.

## Related Projects

* [JOSM Waterway Style](https://josm.openstreetmap.de/wiki/Styles/Waterways)

### Other websites

If you like WaterwayMap.org, you might like the following other websites:

* [Global Watersheds](https://mghydro.com/watersheds/) ([mheberger/delineator](https://github.com/mheberger/delineator) on github)
* [RiverMap.online](https://rivermap.online/)

## FAQ

### What do the colours mean?

The colours are randomly assigned, and based on the final destination of the
river. Everything that flows into the same point, gets the same colour. If you
click the settings, you can change the number of colours. This can be useful to
try to differentiate 2 different river networks.

### Does thickness represent flow rate?

The thickness of the lines is based on how many kilometres of river are
upstream of that segment. The flow rate of a river is based on many things,
such as the width of a river, and obviously changes a lot based on rainfall! I
only use OpenStreetMap data, which rarely has width, and wouldn't have
real-time data about the amount of water flowing through a point! What it does
show (“how many waterways in total are upstream of here?”) will probably
correlate with the flow rate, and is probably good enough for making a map, but
you shouldn't use to see if your house is going to flood!

### If a natural waterway runs through a lake, is it possible to show all the branches as connected waterways?

Currently, the only way to do this is map a waterway _though_ the water body.
There is currently no other way to do it. The OSM community is a little
uncertain if this is always a good idea. There is a [community
discussion](https://community.openstreetmap.org/t/should-river-lines-be-mapped-through-lakes-estuaries-gulfs-and-other-large-water-bodies/104438).
There is a new tag
[`waterway=flowline`](https://wiki.openstreetmap.org/wiki/Tag:waterway%3Dflowline)
as possible tag to use for these ways through waterbodies.

I did try to add a map view which would include the edges of waterbodies,
[e.g.](https://community.openstreetmap.org/t/osm-river-basins-website-to-show-how-are-rivers-in-osm-connected/102655/118)
but that didn't work as well, because it only uses `ways` not `relations`, so
many water bodies weren't included.

However, the latest new feature, the [River Directory](https://waterwaymap.org/river/), could benefit from relation
support. So I might add that.
[cf.](https://community.openstreetmap.org/t/waterwaymap-org-is-not-a-map/127608#:~:text=like%20the%20rest%20of%20wwm%2C%20osm%20waterway%20relations%20are%20completely%20ignored.%20however%2C%20they%E2%80%99re%20probably%20the%20solution%20to%20%E2%80%9Criver%20name%20changes%E2%80%9D%2C%20so%20watch%20this%20space).


## Copyright

Copyright MIT or Apache-2.0, 2017→2024 Amanda McCann <amanda@technomancy.org>

Initially this project was called `osm-river-basins`.


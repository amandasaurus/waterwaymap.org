const htmlElement = document.querySelector("html")
if (htmlElement.getAttribute("data-bs-theme") === 'auto') {
  function updateTheme() {
    document.querySelector("html").setAttribute("data-bs-theme",
      window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light")
  }
  window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', updateTheme)
  updateTheme()
}

const editRemoteButton = document.getElementById("editRemoteButton");

editRemoteButton.addEventListener("click", function () {
  finish();
});

async function remote() {
  let b = map.getBounds();
  let url = `http://127.0.0.1:8111/load_and_zoom?top=${b.getNorth()}&amp;bottom=${b.getSouth()}&amp;left=${b.getWest()}&amp;right=${b.getEast()}&amp;changeset_source=${encodeURIComponent(
    location.href
  )}&amp;changeset_hashtags=${encodeURIComponent("#WaterwayMapOrg")}`;
  let res_ok = await fetch(url).then((r) => r.ok).catch((e) => false);
  this.disabled = false;
  if (!res_ok) {
    show_josm_not_running = true;
    setTimeout(() => (show_josm_not_running = false), 5000);
  }
}

// let b = map.getBounds();
// let url = `http://127.0.0.1:8111/load_and_zoom?new_layer=true&top=${b.getNorth()}&amp;bottom=${b.getSouth()}&amp;left=${b.getWest()}&amp;right=${b.getEast()}&amp;changeset_source=${encodeURIComponent(location.href)}&amp;changeset_hashtags=${encodeURIComponent('#WaterwayMapOrg')}`;
// let res_ok = await fetch(url).then(r => r.ok).catch(e => false);
// this.disabled = false;
// if (!res_ok) {
// 	show_josm_not_running = true;
// 	setTimeout(() => show_josm_not_running = false, 5000);
// }

document.querySelector("#shareButton").addEventListener("click", () => {
  if (navigator.share) {
    navigator
      .share({
        title: "WaterwayMap",
        text: "WaterwayMap.org - OSM River Basins",
        url: location.href,
      })
      .then(() => {
        console.log("Thanks for sharing!");
      })
      .catch(console.error);
  } else {
    navigator.clipboard.writeText(location.href);
    document.querySelector("#shareDialog").classList.remove("d-none");
    setTimeout(() => {
      document.querySelector("#shareDialog").classList.add("d-none");
    }, 5000);
  }
});

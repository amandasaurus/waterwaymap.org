const editRemoteButton = document.getElementById('editRemoteButton')
const editRemoteNewLayerButton = document.getElementById("editRemoteNewLayerButton");
const toastContainer = document.getElementById('toastContainer')
const josmToastTemplate = document.getElementById('josmToastTemplate').content.firstElementChild.cloneNode(true)

if (editRemoteButton) {
  editRemoteButton.addEventListener('click', () => {
    remote()
  })
}

if (editRemoteNewLayerButton) {
  editRemoteNewLayerButton.addEventListener('click', () => {
    remoteNewLayer()
  })
}

async function remote() {
  let b = map.getBounds();
  let url = `http://127.0.0.1:8111/load_and_zoom?top=${b.getNorth()}&bottom=${b.getSouth()}&left=${b.getWest()}&right=${b.getEast()}&changeset_source=${encodeURIComponent(location.href)}&changeset_hashtags=${encodeURIComponent('#WaterwayMapOrg')}`;
  let res_ok = await fetch(url).then((r) => r.ok).catch(() => false);
  this.disabled = false;
  if (!res_ok) {
    const josmToastEl = josmToastTemplate.cloneNode(true)
    toastContainer.appendChild(josmToastEl)
    const toastBootstrap = bootstrap.Toast.getOrCreateInstance(josmToastEl)
    toastBootstrap.show()
    
  }
}

async function remoteNewLayer() {
  let b = map.getBounds();
  let url = `http://127.0.0.1:8111/load_and_zoom?new_layer=true&top=${b.getNorth()}&amp;bottom=${b.getSouth()}&amp;left=${b.getWest()}&amp;right=${b.getEast()}&amp;changeset_source=${encodeURIComponent(location.href)}&amp;changeset_hashtags=${encodeURIComponent('#WaterwayMapOrg')}}`;
  let res_ok = await fetch(url).then((r) => r.ok).catch(() => false);
  this.disabled = false;
  if (!res_ok) {
    const josmToastEl = josmToastTemplate.cloneNode(true)
    toastContainer.appendChild(josmToastEl)
    const toastBootstrap = bootstrap.Toast.getOrCreateInstance(josmToastEl)
    toastBootstrap.show()
  }
}

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

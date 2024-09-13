const editButton = document.getElementById('editButton')
const editIDButton = document.getElementById('editIDButton')
const editRemoteButton = document.getElementById('editRemoteButton')
const editRemoteNewLayerButton = document.getElementById("editRemoteNewLayerButton");
const toastContainer = document.getElementById('toastContainer')
const josmToastTemplate = document.getElementById('josmToastTemplate').content.firstElementChild.cloneNode(true)

if (editButton) {
  editButton.addEventListener('click', () => {
    // Check for preference in local storage. Defaults to iD editor.
    const editorPreference = localStorage.getItem("editor-preference")
    if (editorPreference) {
      if (editorPreference == 'id') {
        idEditor()
      }
      else if (editorPreference == 'remote') {
        remote()
      }
      else if (editorPreference == 'remote-new-layer') {
        remoteNewLayer()
      }
      else {
        console.warn("Malformed localStorage editor-preference:", editorPreference)
        idEditor()
      }
    } else {
      idEditor()
    }
  })
}

if (editIDButton) {
  editIDButton.addEventListener('click', () => {
    idEditor()
    localStorage.setItem("editor-preference", "id")
  })
}

if (editRemoteButton) {
  editRemoteButton.addEventListener('click', () => {
    remote()
    localStorage.setItem("editor-preference", "remote")
  })
}

if (editRemoteNewLayerButton) {
  editRemoteNewLayerButton.addEventListener('click', () => {
    remoteNewLayer()
    localStorage.setItem("editor-preference", "remote-new-layer")
  })
}

function idEditor() {
  let url = `https://www.openstreetmap.org/edit?editor=id#&source=${encodeURIComponent(location.href)}&hashtags=${encodeURIComponent('#WaterwayMapOrg')}&map=${Math.round(map.getZoom())}/${map.getBounds().getCenter().lat}/${map.getBounds().getCenter().lng}`
  window.open(url)
}

async function remote() {
  let b = map.getBounds();
  let url = `http://127.0.0.1:8111/load_and_zoom?new_layer=false&top=${b.getNorth()}&bottom=${b.getSouth()}&left=${b.getWest()}&right=${b.getEast()}&changeset_source=${encodeURIComponent(location.href)}&changeset_hashtags=${encodeURIComponent('#WaterwayMapOrg')}`;
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
  let url = `http://127.0.0.1:8111/load_and_zoom?new_layer=true&top=${b.getNorth()}&bottom=${b.getSouth()}&left=${b.getWest()}&right=${b.getEast()}&changeset_source=${encodeURIComponent(location.href)}&changeset_hashtags=${encodeURIComponent('#WaterwayMapOrg')}`;
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

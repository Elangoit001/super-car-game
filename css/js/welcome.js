const player = localStorage.getItem("player");

if (!player) {
  window.location.href = "index.html"; // safety redirect
}

document.getElementById("playerName").innerText = player;

function goLobby() {
  window.location.href = "lobby.html";
}

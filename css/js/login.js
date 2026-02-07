function login() {
  const name = document.getElementById("name").value.trim();
  if (!name) return alert("Enter name");

  localStorage.setItem("player", name);
  console.log("Saved:", name);

  window.location.href = "welcome.html";
}

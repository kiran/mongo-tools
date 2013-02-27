
function flash(loc, level, msg) {
  button = $("<button />", { class: "close" }).attr("data-dismiss", "alert").append("&times;");
  div = $("<div />", { class: "alert alert-" + level }).append(button).append(msg);
  loc.prepend(div);
};
// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

var editor = CodeMirror.fromTextArea(document.getElementById("collection-terminal"), {
  mode:  "javascript",
  path: "/assets/codemirror",
  lineWrapping: true,
  theme: "twilight",
  indentUnit: 2,
  smartIndent: true,
  tabSize: 2,
  autoFocus: true
});
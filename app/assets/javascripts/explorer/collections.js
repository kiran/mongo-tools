// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

$(function () {
  var terminal = $("#collection-terminal");

  if (terminal.length > 0) {
    var editor = CodeMirror.fromTextArea(terminal[0], {
      mode:  "javascript",
      path: "/assets/codemirror",
      lineWrapping: true,
      theme: "twilight",
      indentUnit: 2,
      smartIndent: true,
      tabSize: 2,
      autoFocus: true,
      onKeyEvent: onEnter
    });

    editor.setSize("100%", "80px");

    function onEnter (e, k) {
      k = $.event.fix(k);
      if (k.which === 13 && k.type === "keydown")
        terminal.parents("form").submit();
    };

  }
});
// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

$(function () {
  var terminal = $("#collection-terminal");

  // Ensure we have a terminal
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

    // Size is set in CSS file... override them
    editor.setSize("100%", "80px");

    // Used for submitting user query on Enter
    function onEnter (e, k) {
      k = $.event.fix(k);
      if (k.which === 13 && k.type === "keydown")
        terminal.parents("form").submit();
    };
  }

  // Hide the respective span elements on click
  $('#collection-form .buttons button.btn-inverse').click(function () {
    $(this).toggleClass('active');
    $('#span-' + $(this).data()['field']).toggle();
    return false;
  });
  
});
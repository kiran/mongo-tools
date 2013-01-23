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

  // Bug fix: prevents breaking the contenteditable box
  // Inserts a zero width space when the content is empty
  var filters = $('#collection-form .params span[contenteditable=true]');
  filters.keyup(function () {
    filters.filter(":empty").html("&#8203;");
  });

  filters.keydown(function (e) {
    e = $.event.fix(e);
    if (e.which == 13) {
      // Make enter submit the form
      e.preventDefault();
      $(this).parents("form").submit();
    } else if (e.which == 8 || e.which == 46) {
      var parent = document.getSelection().anchorNode.parentNode;
      if ($(parent).is(filters) && ($(parent).text() == document.getSelection().toString() || $(parent).html("&#8203;"))) {
        $(parent).html("&#8203;")
        e.preventDefault();
      }
    }
  });

  // Hide the respective span elements on click
  $('#collection-form .buttons button.btn-inverse').click(function () {
    $(this).toggleClass('active');
    $('#span-' + $(this).data()['field']).toggle();
    return false;
  });

  window.onload=function() {
    // get tab container
    var container = document.getElementById("tabs-container");
    var navitem = container.querySelector(".tabs ul li");

    //split on r of tab-header###
    var ident = navitem.id.split("r")[1];
    navitem.parentNode.setAttribute("data-current",ident);
    //set current tab with class of activetabheader
    navitem.setAttribute("class","tabActiveHeader");

    //hide two tab contents we don't need
    var pages = container.querySelectorAll(".tab-page");
    for (var i = 1; i < pages.length; i++) {
      pages[i].style.display="none";
    }

    //this adds click event to tabs
    var tabs = container.querySelectorAll(".tabs ul li");
    for (var i = 0; i < tabs.length; i++) {
      tabs[i].onclick=displayPage;
    }
  }

  // on click of one of tabs
  function displayPage() {
    var current = this.parentNode.getAttribute("data-current");
    //remove class of activetabheader and hide old contents
    document.getElementById("tab-header" + current).removeAttribute("class");
    document.getElementById("tab-page" + current).style.display="none";

    //split on r of tab-header###
    var ident = this.id.split("r")[1];
    //add class of activetabheader to new active tab and show contents
    this.setAttribute("class","tabActiveHeader");
    document.getElementById("tab-page" + ident).style.display="block";
    this.parentNode.setAttribute("data-current",ident);
  }

});


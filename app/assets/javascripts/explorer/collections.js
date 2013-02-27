// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

$(function () {
 
 /*$('.formatted').each(function() {
  var $this = $(this);
} */

 $('.colltxt').keyup( function(){
  $('.message').empty(); //empties the div
  $('input[type=submit]').removeAttr('disabled');
  var colname = $('.colltxt').val();
 
  if(colname ==" ")//collection name must not be empty
   {
       $('.message').append('<div class = \'alert\'><strong>Error!</strong> Collection name can\'t be empty.</div>'); 
	if($('div.alert').length == 0) {
          flash($this.closest('div'), 'error', '<strong>Error!</strong> Collection name can\'t be empty.');
        }
	$('input[type=submit]').attr('disabled', 'disabled'); 
   }
   else if(colname.indexOf("$") !=-1) //collection name must not contain '$'
   {
       $('.message').append('<div class = \'alert\'><strong>Error!</strong> Collection name can\'t contain \'$\'</div>'); 
	if($('div.alert').length == 0) {
          flash($this.closest('form'), 'error', '<strong>Error!</strong> Collection name can\'t be empty.');
        }
      $('input[type=submit]').attr('disabled', 'disabled'); 

   }else if(colname.search("system.") == 0)//must not begin with 'system.'
   {
    
    $('.message').append('<div class = \'alert\'><strong>Error!</strong> Collection name can\'t begin with \'system\'</div>'); 
    $('input[type=submit]').attr('disabled', 'disabled'); 

   }
   

 })//end 'colltxt'onkeyup()


  // query functions
  function validateHash(elem) {
    t = '{' + sanitizedElementText(elem) + '}';
    validateQuery(elem, t);
  };

  function validateQuery(elem, query) {
    try {
      eval('(' + query + ')');
      $(elem).css({ 'border-bottom-color': 'white' });
    } catch (e) {
      $(elem).css({ 'border-bottom-color': 'red' });
    }
  };

  function validateNumber(elem) {
    if (isNaN(sanitizedElementText(elem))) {
      $(elem).css({ 'border-bottom-color': 'red' });
    } else {
      $(elem).css({ 'border-bottom-color': 'white' });
    }
  }

  function sanitizedElementText(elem) {
    return $("<div></div>").html($(elem).html().replace(/[\u200B-\u200D\uFEFF]/g, '')).text();
  };

  // codemirror
  var $terminal = $("#collection-terminal");

  // Ensure we have a terminal
  if ($terminal.length > 0) {
    var editor = CodeMirror.fromTextArea($terminal[0], {
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
  }

  // Bug fix: prevents breaking the contenteditable box
  // Inserts a zero width space when the content is empty
  var filters = $('#collection-form .params span[contenteditable=true]');
  filters.keyup(function () {
    filters.filter(":empty").html("&#8203;");

    if ($(this).data("type") == "hash") {
      validateHash(this);
    } else if ($(this).data("type") == "number") {
      validateNumber(this);
    }
  });

  filters.keydown(function (e) {
    e = $.event.fix(e);
    if (e.which == 13) {
      // Make enter submit the form
      e.preventDefault();
      $(this).parents("form").submit();
    } else if (e.which == 8 || e.which == 46) {
      var parent = document.getSelection().anchorNode.parentNode;
      if ($(parent).is(filters) && ($(parent).text() == document.getSelection().toString() || $(parent).html() == "&#8203;")) {
        $(parent).html("&#8203;");
        e.preventDefault();
      }
    }
  });

  $('#collection-form').submit(function() {
    var params = {};
    $(this).find("span[data-name]").each(function (index, elem) {
      if ($(elem).is(":visible")) {
        params[$(elem).data("name")] = sanitizedElementText(elem);
      }
    });
    params["explain"] = $("#span-explain").is(":visible");

    $.ajax({
      type: "GET",
      data: params,
      success: function(data) {
        $("#results").replaceWith(data);
      },
      error: function() {

      }
    });

    return false;
  });

  // Hide the respective span elements on click
  $('#collection-form .buttons button.btn-inverse').click(function () {
    $(this).toggleClass('active');
    $('#span-' + $(this).data()['field']).toggle();
    return false;
  });

  // Used for submitting user query on Enter
  function onEnter (e, k) {
    k = $.event.fix(k);
    if (k.which === 13 && k.type === "keydown")
      terminal.parents("form").submit();
  };
});

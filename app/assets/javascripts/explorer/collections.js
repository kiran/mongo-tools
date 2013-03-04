// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

$(function () {
 

 $('.colltxt').keyup( function(){
  $('.alert alert-error').empty(); //empties the div
  $('input[type=submit]').removeAttr('disabled');
  var colname = $('.colltxt').val();

  if(colname.replace(/\s/g, "") =="")//collection name must not be empty
   {
        if($('div.alert').length == 0) 
          flash($('#addcollfrm'), 'error', '<strong>Error!</strong> Collection name can\'t be empty.');
        $('.btn-primary').addClass("disabled");
	$('input[type=submit]').attr('disabled', 'disabled'); 
   }
   else if(colname.indexOf("$") !=-1) //collection name must not contain '$'
   {
	if($('div.alert').length == 0) {
          flash($('#addcollfrm'), 'error', '<strong>Error!</strong> Collection name can\'t be empty.');
        }
      $('.btn-primary').addClass("disabled");	
      $('input[type=submit]').attr('disabled', 'disabled'); 

   }else if(colname.search("system.") == 0)//must not begin with 'system.'
   {
    if($('div.alert').length == 0) {
          flash($('#addcollfrm'), 'error', '<strong>Error!</strong> Collection name can\'t begin with \'system\'');
    }
    $('.btn-primary').addClass("disabled");
    $('input[type=submit]').attr('disabled', 'disabled'); 

   }
   

 })//end 'colltxt'onkeyup()


  var typingTimer;
  var doneTypingInterval = 650;  //time in ms

  // Bug fix: prevents breaking the contenteditable box
  // Inserts a zero width space when the content is empty
  var filters = $('#collection-form .params span[contenteditable=true]');
  filters.keyup(function () {
    // Detect when the user has stopped typing and validate the fields
    clearTimeout(typingTimer);
    if ($(this).val) {
        typingTimer = setTimeout(validateFields, doneTypingInterval);
    }

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
    if(validateFields()) {
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
    }

    return false;
  });

  // Hide the respective span elements on click
  $('#collection-form .buttons button.btn-inverse').click(function () {
    $(this).toggleClass('active');
    $('#span-' + $(this).data()['field']).toggle();
    return false;
  });

    // query functions
  function validateHash(elem) {
    t = '{' + sanitizedElementText(elem) + '}';
    return validateQuery(elem, t);
  };

  function validateQuery(elem, query) {
    try {
      eval('(' + query + ')');
      $(elem).css({ 'border-bottom-color': 'white' });
      return true;
    } catch (e) {
      $(elem).css({ 'border-bottom-color': 'red' });
      return false;
    }
  };

  function validateNumber(elem) {
    if (isNaN(sanitizedElementText(elem))) {
      $(elem).css({ 'border-bottom-color': 'red' });
      return false;
    } else {
      $(elem).css({ 'border-bottom-color': 'white' });
      return true;
    }
  }

  // validate all fields
  function validateFields() {
    try {
      $('#collection-form').find("span[data-name]").each(function (index, elem) {
        if ($(elem).is(":visible")) {
          if (($(elem).data("type") == "hash" && !validateHash(elem))
            || ($(elem).data("type") == "number" && !validateNumber(elem))) {
            throw "Invalid Query.";
          }
        }
      });
      $('#submit').removeClass('disabled');
      $('#submit').removeAttr('disabled');
      return true;
    }
    catch(e) {
      $('#submit').addClass('disabled');
      $('#submit').attr('disabled', 'disabled');
      //Only display the error message once, until cleared
      if($('div.alert').length == 0) {
        flash($('#collection-form'), 'error', '<strong>Error!</strong> Invalid Query.');
      }
      return false;
    }       
  };

  function sanitizedElementText(elem) {
    return $("<div></div>").html($(elem).html().replace(/[\u200B-\u200D\uFEFF]/g, '')).text();
  };

});

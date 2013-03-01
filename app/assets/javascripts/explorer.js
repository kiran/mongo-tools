// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.




var validateDatabaseName = function(){
  $('.alert alert-error').empty(); //empties the div
  $('#Errors').empty();
  $('input[type=submit]').removeAttr('disabled');
  $('.btn-primary').removeClass("disabled");
  var colname = $('.dbtxt').val();
    //database  name must not be empty
    if(colname.replace(/\s/g, "") == "") {
      if($('div.alert').length == 0) {
        flash($('#Errors'), 'error', '<strong>Error!</strong> Database name can\'t be empty.');
      }
      $('.btn-primary').addClass("disabled");
      $('input[type=submit]').attr('disabled', 'disabled');
      return true;
    }
    else if( /([\/\\\. $])/.test(colname)){
      if($('div.alert').length == 0) {
        flash($('#Errors'), 'error', '<strong>Error!</strong> Database name can\'t have invalid characters.');
      }
      $('.btn-primary').addClass("disabled");
      $('input[type=submit]').attr('disabled', 'disabled');
      return true;
    }
    else if (colname.indexOf(".") == 0 || colname.indexOf(".") == colname.length - 1) {
      if($('div.alert').length == 0) {
        flash($('#Errors'), 'error', '<strong>Error!</strong> Collection name can\'t begin or end with \'.\'');
      }
      $('.btn-primary').addClass("disabled");
      $('input[type=submit]').attr('disabled', 'disabled');
      return true;
    }
    return false;
  };



$(document).ready(function() {

    $('.dbtxt').keyup(function(){
      validateDatabaseName();
    });

    $('.db_submit').click(function(){
      if(validateDatabaseName()){
        return false;
      }
      $('.alert alert-error').empty(); //empties the div
      $('.alert alert-error').html(''); //empties the div
      var valid = true
      params = {};
      params["db"]= $('#db').val();
      $.ajax({
        type: "GET",
        async: false,
        data: params,
        dataType: 'text' ,
        async: false,
        success: function(data) {
          if(data != 'OK')
          {
            flash($('#Errors'), 'error', '<strong>Error!</strong> Database already exists in the system.');
            $('.btn-primary').addClass("disabled");
            $('input[type=submit]').attr('disabled', 'disabled');
              valid = false
            }
            else
            {
              valid = true;
            }
          },
          error: function() {
            alert('error')
          }
        });
      return valid;
    });
  });
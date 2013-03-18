// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

$(function () {

  $('.colltxt').keyup(function(){
    $('.alert alert-error').empty(); //empties the div
    $('input[type=submit]').removeAttr('disabled');
    var colname = $('.colltxt').val();

    //collection name must not be empty
    if(colname.replace(/\s/g, "") == "") {
      if($('div.alert').length == 0) {
        flash($('#addcollfrm'), 'error', '<strong>Error!</strong> Collection name can\'t be empty.');
      }

      $('.btn-primary').addClass("disabled");
      $('input[type=submit]').attr('disabled', 'disabled');
    }
     //collection name must not contain '$'
    else if(colname.indexOf("$") != -1) {
      if($('div.alert').length == 0) {
        flash($('#addcollfrm'), 'error', '<strong>Error!</strong> Collection name can\'t be empty.');
      }
      $('.btn-primary').addClass("disabled");
      $('input[type=submit]').attr('disabled', 'disabled');

    }
    //must not begin with 'system.'
    else if(colname.search("system.") == 0) {
      if($('div.alert').length == 0) {
        flash($('#addcollfrm'), 'error', '<strong>Error!</strong> Collection name can\'t begin with \'system.\'');
      }
      $('.btn-primary').addClass("disabled");
      $('input[type=submit]').attr('disabled', 'disabled');

    }
    else if (colname.indexOf(".") == 0 || colname.indexOf(".") == colname.length - 1) {
      if($('div.alert').length == 0) {
        flash($('#addcollfrm'), 'error', '<strong>Error!</strong> Collection name can\'t begin or end with \'.\'');
      }
      $('.btn-primary').addClass("disabled");
      $('input[type=submit]').attr('disabled', 'disabled');
    }
  });
  //end 'colltxt'onkeyup()

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

  $('#languages-dropdown > li').on('click', function () {
    if (validateFields()) {
      var out = $('#query');
      var selection = $(this).attr('id');
      if (selection != "0") {
        var mode = (selection == "node") ? "javascript" : selection;

        var editor = CodeMirror.fromTextArea(out.get(0), {
            path: "/assets/codemirror",
            mode: {
                name: mode
            },
            tabSize: 2,
            matchBrackets: 1
        });

        var lang = language_formatters[selection];
        var params = {};
        $('#collection-form').find("span[data-name]").each(function (index, elem) {
          if ($(elem).is(":visible") && ($.trim(sanitizedElementText(elem))).length > 0) {
            if ($(elem).data("type") == "hash") {
              params[$(elem).data("name")] = eval('({' + sanitizedElementText(elem) + '})');
            }
            else {
              params[$(elem).data("name")] = eval('(' + sanitizedElementText(elem) + ')');
            }
          }
        });

        params["explain"] = eval($("#span-explain").is(":visible"));
        var query = lang.import() + lang.before() + lang.query(params);
        editor.setValue(query);
        var totalLines = editor.lineCount();
        if(mode != "javascript") {
          editor.autoFormatRange({line:0, ch:0}, {line:totalLines - 1, ch:editor.getLine(totalLines - 1).length});
        }
        editor.setCursor({line:0,chr:0});
        out.data('CodeMirrorInstance', editor);
        $('#modal-language').html(selection.charAt(0).toUpperCase() + selection.substr(1).toLowerCase());
        $('#languages-modal').modal().css({
           'width': function () {
               return ($(document).width() * .3) + 'px';
           }});
      }
    }

    return false;
  });

  $('#languages-modal').on('shown', function () {
    var editor = $('#query').data('CodeMirrorInstance');
    if(editor != undefined && editor != null) {
      editor.refresh();
    }
  });


  $('#languages-modal').on('hidden', function () {
    $('#languages-modal-dropdown').val('0');
    var editor = $('#query').data('CodeMirrorInstance');
    if(editor != undefined && editor != null) {
      editor.toTextArea();
    }
    $('#query').empty().hide();
  });

  function formatHash(ret, key, value) {
    switch(typeof value){
      case "string":
        return ret + '"' + key + '" => "' + value + '"';
      case "number":
        return ret + '"' + key + '" => ' + value;
      case "object":
        if(!$.isEmptyObject(value)) {
          if(key != null) {
            ret += '{' + '"' + key + '" => ';
          }

          $.each(value, function(k, v) {
            if(value.hasOwnProperty(k)) {
              ret += "{";
              ret = formatHash(ret, k, v);
              ret += "}";
            }
          });
        }
        return ret;
      case "boolean":
        return ret + '"' + key + '" => ' + value;
      default:
        return ret;
    }
  };

  function isNumber(n) {
    return !isNaN(parseFloat(n)) && isFinite(n);
  };

  var language_formatters = {
    node: {
      import: function() {
        return "var MongoClient = require('mongodb').MongoClient;\n" +
                "var Server = require('mongodb').Server;\n";
      },

      before: function() {
        return "var mongoClient = new MongoClient(new Server('localhost', 27017));\n" +
                "mongoClient.open(function(err, mongoClient) {\n" +
                "\tvar db = mongoClient.db('" + current_database_name + "');\n";
      },

      query: function(params) {
        var ret = "db.collection('" + current_collection_name + "').find(";

        if(!$.isEmptyObject(params['query'])) {
          ret += JSON.stringify(params['query']);
        }

        if(!$.isEmptyObject(params['fields'])) {
          ret += ', ';
          ret += JSON.stringify(params['fields']);
          ret += ')';
        }
        else {
          ret += ')';
        }

        if(!$.isEmptyObject(params['sort'])) {
          ret += '.sort(';
          ret += JSON.stringify(params['sort']);
          ret += ')';
        }

        if (isNumber(params['skip'])) {
          ret += '.skip(' + params['skip'] + ')';
        }

        if (isNumber(params['limit'])) {
          ret += '.limit(' + params['limit'] + ')';
        }

        if (params['explain']) {
          return '\t' + ret + '.explain(function(err, explanation) {\n\t\tmongoClient.close();\n\t});\n});';
        }
        else {
           return '\tvar cursor = ' + ret + ';\n\tmongoClient.close();\n});';
        }
      }
    },
    python: {
      import: function() {
        return 'import pymongo\n';
      },

      before: function() {
        return 'mongo_client = pymongo.MongoClient()\n' +
          'db = mongo_client["' + current_database_name + '"]\n' +
          'coll = db["' + current_collection_name + '"]\n';
      },

      query: function(params) {
        var ret = "coll.find(";

        if(!$.isEmptyObject(params['query'])) {
          ret += JSON.stringify(params['query']);
        }

        if(!$.isEmptyObject(params['fields'])) {
          ret += ', ';
          ret += JSON.stringify(params['fields']);
          ret += ')';
        }
        else {
          ret += ')';
        }

        if(!$.isEmptyObject(params['sort'])) {
          ret += '.sort([';

          $.each(params['sort'], function(key, value) {
            if(params['sort'].hasOwnProperty(key)) {
              var constant = (value == 1) ? 'pymongo.ASCENDING' : 'pymongo.DESCENDING';
              ret += '("' + key + '", ' + constant + '), ';
            }
          });

          ret = ret.substring(0, ret.length - 2) + '])';
        }

        if (isNumber(params['skip'])) {
          ret += '.skip(' + params['skip'] + ')';
        }

        if (isNumber(params['limit'])) {
          ret += '.limit(' + params['limit'] + ')';
        }

        if (params['explain']) {
          return 'explanation = ' + ret + '.explain()';
        }
        else {
          return 'cursor = ' + ret;
        }
      }
    },

    ruby: {
      import: function() {
        return "require 'mongo'\ninclude Mongo\n";
      },

      before: function () {
        return 'mongo_client = MongoClient.new\n' +
          'db = mongo_client.db("' + current_database_name + '")\n' +
          'coll = db.collection("'+ current_collection_name + '")\n';
      },

      query: function (params) {
        var ret = "coll.find(";

        if(!$.isEmptyObject(params['query'])) {
          ret = formatHash(ret, null, params['query']);
          ret += ', {';
        }
        else {
          ret += '{}, {';
        }

        if(!$.isEmptyObject(params['fields'])) {
          ret += ':fields => ';
          ret = formatHash(ret, null, params['fields']);
          ret += ', ';
        }

        if(!$.isEmptyObject(params['sort'])) {
          ret += ':sort => [';

          $.each(params['sort'], function(key, value) {
            if(params['sort'].hasOwnProperty(key)) {
              var constant = (value == 1) ? 'Mongo::ASCENDING' : 'Mongo::DESCENDING';
              ret += '["' + key + '", ' + constant + '], ';
            }
          });

          ret = ret.substring(0, ret.length - 2) + '], ';
        }

        if (isNumber(params['skip'])) {
          ret += ':skip => ' + params['skip'] + ', ';
        }

        if (isNumber(params['limit'])) {
          ret += ':limit => ' + params['limit'] + '})';
        }
        else {
          ret += ret.substring(0, ret.length - 2) + '})';
        }

        if (params['explain']) {
          return 'explanation = ' + ret + '.explain';
        }
        else {
          return 'cursor = ' + ret;
        }
      }
    }
  };

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
      $('#submit').removeClass('disabled').removeAttr('disabled');
      $('#languages').removeClass('disabled').removeAttr('disabled');
      return true;
    }
    catch(e) {
      $('#submit').addClass('disabled').attr('disabled', 'disabled');
      $('#languages').addClass('disabled').attr('disabled', 'disabled');
      return false;
    }       
  };

  function sanitizedElementText(elem) {
    return $("<div></div>").html($(elem).html().replace(/[\u200B-\u200D\uFEFF]/g, '')).text();
  };

});

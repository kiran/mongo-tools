// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.



var sanitizeRegex = function (e) {
  var t, n, r;
  for (t in e) r = e[t], r instanceof RegExp ? (n = r.toString().match(/^\/(.*)\/([gim]*)$/), e[t] = {
    $regex: n[1],
    $options: n[2]
  }) : t === "$oid" && typeof r == "undefined" ? e[t] = window.dblayer.page_data.document_oids.shift() : t === "$date" && typeof r == "undefined" ? e[t] = (new Date).getTime() : typeof r == "object" && (e[t] = sanitizeRegex(r));
  return e
};

var bsonEval = function (bson) {
  try {
    var parsed = {};
        
    parsed.ObjectId = function (e) {
      return e;
      // return {
      //                 '$oid': e
      //             }
    };

    parsed.Date = function (e) {
      return {
          '$date': e
      }
    };
        
    parsed.ISODate = function (e) {
      return {
          '$date': (new Date(e)).toISOString()
      }
    };
        
    parsed.Timestamp = function (e, t) {
      return {
        '$timestamp': {
            t: e,
            i: t
        }
      }
    };
        
    parsed.Dbref = function (e, t) {
      return {
        '$ref': e,
        '$id': t
      }
    };
        
    var bsonj = (new Function("with(this){ return " + bson + " }")).call(parsed);
        
    return bsonj;
  } catch (s) {
    throw "Invalid BSON";
  }
};


$(function() {
    
  var doneTypingInterval = 650;  //time in ms
  
  $('.formatted').each(function() {
    var $this = $(this);
    var typingTimer;      //timer identifier

    var field = CodeMirror.fromTextArea(this, {
        readOnly: $this.is('.readonly'),
        path: "/assets/codemirror",
        mode: {
            name: "javascript",
            json: !0
        },
        tabSize: 2,
        matchBrackets: 1,
        onKeyEvent: function(e , s){
          if (s.type == "keyup")
          {
            typingTimer = setTimeout(validateJSON, doneTypingInterval);  
          } else if (s.type == "keydown") {
            clearTimeout(typingTimer);
          }
        }
    });
    
    var totalLines = field.lineCount();
    var totalChars = field.getTextArea().value.length;
    field.autoFormatRange({line:0, ch:0}, {line:totalLines, ch:totalChars});
    field.setCursor({line:0,chr:0});
    
    //user is "finished typing," do something
    function validateJSON () {
      field.save();
      var editorVal = $this.val();
      try {
        var evaled = bsonEval(editorVal);
        var json = JSON.stringify(evaled, null, 2);
        var this_json = jQuery.parseJSON(json);
        $('.btn-primary').removeClass("disabled");
        $('.btn-primary').removeAttr('disabled');
      }
      catch(e) {
        $('.btn-primary').addClass("disabled");
        $('.btn-primary').attr('disabled', 'disabled');
        //Only display the error message once, until cleared
        if($('div.alert').length == 0) {
          flash($this.closest('form'), 'error', '<strong>Error!</strong> Document is Invalid.');
        }
      }       
    };

    $this.closest('form').submit(function() {
      field.save();
      var editorVal = $this.val();
      var evaled = bsonEval(editorVal);
      var json = JSON.stringify(evaled, null, 2);
      $this.val(json);
      return true;
    });
  });
  
});
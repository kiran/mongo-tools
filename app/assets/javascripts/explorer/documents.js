// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

if (document.getElementById("new-document-editor")) {
  var newEditor = CodeMirror.fromTextArea(document.getElementById("new-document-editor"), {
    path: "/assets/codemirror",
    mode: {
        name: "javascript",
        json: !0
    },
    indentUnit: 2,
    matchBrackets: 1
  });
}

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
        throw "Invalid BSON"
    }
};

$(document).ready(function() {
  $("#new-document-form").submit(function() {
      var editorVal = newEditor.getValue();
      var evaled = bsonEval(editorVal);
      $("#new-document-editor").val(JSON.stringify(evaled, null, 2));
      alert($("#new-document-editor").val());
      return true;
  });
});
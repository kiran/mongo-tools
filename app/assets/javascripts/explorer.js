// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

 function validateCollName(){
   
   var colname =  document.frm.colname.value;
   if(colname =="")//collection name must not be empty
   {document.getElementById("colldiv").innerHTML = "<div class = \"alert alert-error\">Please enter a collection name </div>"; 
    document.getElementById("btndiv").innerHTML = ""; 
}

   else if(colname.indexOf("$") !=-1) //collection name must not contain '$'
   {document.getElementById("colldiv").innerHTML = "<div class = \"alert alert-error\">Collection name cannot contain '$'</div>"; 
   document.getElementById("btndiv").innerHTML = ""; }
   else if(colname.search("system.") == 0)//must not begin with 'system.'
   {document.getElementById("colldiv").innerHTML = "<div class = \"alert alert-error\">Collection name can not begin with 'system.'</div>"; 
document.getElementById("btndiv").innerHTML = ""; }
   else 
   {document.getElementById("colldiv").innerHTML = ""; document.getElementById("btndiv").innerHTML = "<button type=\"submit\" class=\"btn\">Save Collection</button>"}

    
}


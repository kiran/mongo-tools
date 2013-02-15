
function flash(loc, level, msg) {
  loc.prepend('<div class="alert alert-'+level+'"><button type="button" class="close" data-dismiss="alert">&times;</button>'+msg+'</div>');
};
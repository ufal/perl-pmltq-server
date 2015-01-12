(function($, undefined) {

/**
 * Some parts inspired by Unobtrusive scripting adapter for jQuery
 * https://github.com/rails/jquery-ujs
 */

var $document = $(document);

function handleMethod(link) {
  var href = link.attr('href'),
    method = link.data('method'),
    form = $('<form method="post" action="' + href + '"></form>'),
    metadataInput = '<input name="_method" value="' + method + '" type="hidden" />';

  form.hide().append(metadataInput).appendTo('body');
  form.submit();
}

$document.delegate('a[data-method]', 'click.pmltq-admin', function(e) {
  var link = $(this);

  link.prop('disabled', true);
  handleMethod(link);
  return false;
});

})( jQuery );

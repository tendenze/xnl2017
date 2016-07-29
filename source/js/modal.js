$(document).ready(function () {
  $(".modal").on('hidden.bs.modal', function() {
    $(this).find(".modal-container").remove();
    $(this).data('bs.modal', null);
  });
});

function trigger_image_loading(placeholder) {
  var num = placeholder.getAttribute("data-trigger");
  var images = $(".band .image img[data-trigger='" + num + "']");
  for(var i = 0; i < images.length; i++) {
    if(images[i].getAttribute("data-src")) {
      images[i].setAttribute("src", images[i].getAttribute("data-src"));
    }
  };
}

function check_placeholders(placeholders) {
  var idx = -1;
  for (var i = 0; i < placeholders.length; i++) {
    if($(placeholders[i]).offset().top - ($(window).scrollTop() + $(window).height()) < 400) {
      trigger_image_loading(placeholders[i]);
      idx = i;
    }
  };
  if(idx !== -1) {
    placeholders.splice(0, idx + 1);
  }
}

var scroll_timeout = null;
var placeholders = $(".band .image.placeholder");
window.onload = function() {
  trigger_image_loading(placeholders.splice(0, 1)[0]);
  check_placeholders(placeholders);
};

function scroll_handler() {
  check_placeholders(placeholders);
}

$(window).scroll(function() {
  if(placeholders.length === 0) return;
  if(scroll_timeout) {
    window.clearTimeout(scroll_timeout);
    scroll_timeout = null;
  }
  scroll_timeout = window.setTimeout(scroll_handler, 300);
});

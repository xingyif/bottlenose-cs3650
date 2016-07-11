// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require jquery
//= require bootstrap-sprockets
//= require jquery_ujs
//= require jquery.matchHeight
//= require jquery-tablesorter
//= require nicEdit
//= require moment
//= require bootstrap-datetimepicker
//= require jquery.keyDecoder
//= require codemirror
//= require codemirror/addons/runmode/runmode
//= require codemirror/addons/selection/active-line
//= require codemirror/modes/clike
//= require codemirror/modes/javascript
//= require codemirror/modes/scheme
//= require_tree .

$(function() {
    $('[data-toggle="tooltip"]').tooltip()

    $('.local-time').each(function(_) {
        var dd = new Date($(this).text());

        if (!isNaN(dd.getTime())) {
          $(this).text(dd);
        }
    });
})

$(function() {
  $("#lateness-configuration .equal-height-group")
    .matchHeight({byRow: false, property: 'height'});
  $('.spinner').each(function() {
    var spinner = $(this);
    var input = spinner.find('input');
    var upArrow = spinner.find('.btn:first-of-type');
    var downArrow = spinner.find('.btn:last-of-type');
    var upInterval, downInterval;
    var delta = input.data("delta") || 1;
    var max = input.data("max");
    var min = input.data("min");
    var val = parseInt(input.val(), 10);
    if (max !== undefined && val >= max)
      upArrow.addClass("disabled");
    if (min !== undefined && val <= min)
      downArrow.addClass("disabled");
    function validate() {
      var val = parseInt(input.val(), 10);
      if (max !== undefined && val >= max) {
        upArrow.addClass("disabled");
        clearInterval(upInterval);
        upInterval = undefined;
      }
      if (min === undefined || val > min)
        downArrow.removeClass("disabled");
      if (min !== undefined && val <= min) {
        downArrow.addClass("disabled");
        clearInterval(downInterval);
        downInterval = undefined;
      }
      if (max === undefined || val < max)
        upArrow.removeClass("disabled");
    }
    input.on("change", validate);
    function increment() {
      var newVal = parseInt(input.val(), 10) + delta;
      if (max !== undefined) {
        newVal = Math.min(max, newVal);
      }
      input.val(newVal);
      validate();
    }
    function decrement() {
      var newVal = parseInt(input.val(), 10) - delta;
      if (min !== undefined) {
        newVal = Math.max(min, newVal);
      }
      input.val(newVal);
      validate();
    }
    $(upArrow).on('mousedown', function() {
      upInterval = setInterval(increment, 200);
      increment();
    });
    $(downArrow).on('mousedown', function() {
      downInterval = setInterval(decrement, 200);
      decrement();
    });
    $(document).on('mouseup', function() {
      if (upInterval) clearInterval(upInterval);
      if (downInterval) clearInterval(downInterval);
      upInterval = undefined;
      downInterval = undefined;
      return false;
    });
  });
});

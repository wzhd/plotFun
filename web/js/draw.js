$(document).ready(function() {
  $('#equation').focus();
  $('#slider').slider({ min: 1, max: 250, value: 100 });
  $('#slider').on('slide', function() {
    drawGraph();
  });
  $('input').on('textchange', function() {
    drawGraph();
  });
  $('#more').on('click', function() {
    if ($('.equation4').css('display') === 'inline-block') $('.equation5').fadeIn();
    if ($('.equation3').css('display') === 'inline-block') $('.equation4').fadeIn();
    if ($('.equation2').css('display') === 'inline-block') $('.equation3').fadeIn();
    $('.equation2').fadeIn();
  });

  function drawGraph() {
    var plot = xkcdplot();
    drawGraphEquation(plot, '#equation');
    if ($('#equation2').val()) drawGraphEquation(plot, '#equation2', 'red');
    if ($('#equation3').val()) drawGraphEquation(plot, '#equation3', 'green');
    if ($('#equation4').val()) drawGraphEquation(plot, '#equation4', 'purple');
    if ($('#equation5').val()) drawGraphEquation(plot, '#equation5', 'gray');
  }

  function drawGraphEquation(plot, equation, color) {
    $('#plot').empty();
    if (!color) color = 'steelBlue';

    var expression = string_eval($(equation).val()),
        xmin = parseInt($('#xmin').val()),
        xmax = parseInt($('#xmax').val()),
        N = $('#slider').slider('option', 'value');

    if (expression != "'Invalid function'" && !isNaN(xmin) && !isNaN(xmax) && xmin < xmax) {

      function f(d) {
        current_expression = expression.split('-x').join(-d);
        var result = eval(current_expression.split('x').join(d));
        if (isNaN(result)) {
          return 0;
        } else if (result === -Infinity) {
          return -25;
        } else if (result === Infinity) {
          return 25;
        } else {
          return result;
        }
      }

      var data = d3.range(xmin, xmax, (xmax - xmin) / N).map(function(d) {
        return {x: d, y: f(d)};
      });

      var parameters = { title: $('#title').val(),
                          xlabel: $('#xlabel').val(),
                          ylabel: $('#ylabel').val(),
                          xlim: [xmin - (xmax - xmin) / 16, xmax + (xmax - xmin) / 16] };

      if (expression.indexOf('x') < 0) {
        if (eval(expression) < -10) {
          parameters['ylim'] = [eval(expression), 10];
        } else if (eval(expression) > 10) {
          parameters['ylim'] = [-10, eval(expression)];
        } else {
          parameters['ylim'] = [-10, 10];
        }
      }

      plot('#plot', parameters);
      plot.plot(data, {stroke: color});
      plot.draw();

      for (var i = xmin; i < xmax; i++) {
        current_expression = expression.split('-x').join(-i);
        var result = eval(current_expression.split('x').join(i));
        if (isNaN(result) || result === Infinity) {
          $('#plot').append('<h1>Some part of the equation is invalid along the domain you chose</h1>');
          break;
        }
      }

      console.log('[Graph Equation] ' + $('#equation').val());
      console.log('[JS Expression] ' + expression);
    } else {
      $('#plot').append('<h1>Sorry, invalid function</h1>');
      console.log('[Invalid Function] ' + $('#equation').val());
    }
  }

});

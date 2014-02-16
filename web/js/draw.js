angular.module('PlotFunApp', []).controller('PlotFunCtrl', function() {
  this.morePlots = function() {
    if (this.showEquation4 === true) this.showEquation5 = true;
    if (this.showEquation3 === true) this.showEquation4 = true;
    if (this.showEquation2 === true) this.showEquation3 = true;
    this.showEquation2 = true;
  };

  this.drawGraph = function() {
    var plot = xkcdplot();
    this.drawGraphEquation(plot, this.equation);
    if (this.showEquation2) this.drawGraphEquation(plot, this.equation2, 'red');
    if (this.showEquation3) this.drawGraphEquation(plot, this.equation3, 'green');
    if (this.showEquation4) this.drawGraphEquation(plot, this.equation4, 'purple');
    if (this.showEquation5) this.drawGraphEquation(plot, this.equation5, 'gray');
  };

  this.drawGraphEquation = function(plot, equation, color) {
    angular.element(document.querySelector('#plot')).empty();
    if (!color) color = 'steelBlue';

    var expression = string_eval(equation);
    this.xmin = this.xmin ? this.xmin : -10;
    this.xmax = this.xmax ? this.xmax : 10;

    if (expression != "'Invalid function'" && !isNaN(this.xmin) && !isNaN(this.xmax) && this.xmin < this.xmax) {
      this.invalidFunction = false;
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

      var data = d3.range(this.xmin, this.xmax, (this.xmax - this.xmin) / this.fineness) .map(function(d) {
        return {x: d, y: f(d)};
      });

      var parameters = {
        title: this.title,
        xlabel: this.xlabel,
        ylabel: this.ylabel,
        xlim: [this.xmin - (this.xmax - this.xmin) / 16,
               this.xmax + (this.xmax - this.xmin) / 16] };

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

      for (var i = this.xmin; i < this.xmax; i++) {
        current_expression = expression.split('-x').join(-i);
        var result = eval(current_expression.split('x').join(i));
        if (isNaN(result) || result === Infinity) {
          this.invalidFunction = true;
          this.warning = 'Some part of the equation is invalid along the domain you chose';
          break;
        }
      }

      console.log('[Graph Equation] ' + this.equation);
      console.log('[JS Expression] ' + expression);
    } else {
      this.invalidFunction = true;
      this.warning = 'Sorry, invalid function';
      console.log('[Invalid Function] ' + this.equation);
    }
  };
});

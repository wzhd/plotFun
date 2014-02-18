library plot_fun_controller;

import 'dart:html';
import 'dart:js';
import 'package:angular/angular.dart';
import 'package:math_expressions/math_expressions.dart' as Mathexp;

@NgController(
    selector: '[plot-fun]',
    publishAs: 'ctrl')
  class PlotFunController {
    //variables
    String title;
    String xlabel;
    String ylabel;
    String equation;
    String equation2;
    String equation3;
    String equation4;
    String equation5;
    int xmin = -10;
    int xmax = 10;
    int fineness = 200;
    bool showEquation2 = false;
    bool showEquation3 = false;
    bool showEquation4 = false;
    bool showEquation5 = false;
    bool invalidFunction = false;
    String warning;

    void morePlots() {
      if (showEquation4 == true) showEquation5 = true;
      if (showEquation3 == true) showEquation4 = true;
      if (showEquation2 == true) showEquation3 = true;
      showEquation2 = true;
    }

    void drawGraph() {
      JsObject plot = new JsObject(context['xkcdplot']);
      drawGraphEquation(plot, equation, 'steelBlue');
      if (showEquation2) drawGraphEquation(plot, equation2, 'red');
      if (showEquation3) drawGraphEquation(plot, equation3, 'green');
      if (showEquation4) drawGraphEquation(plot, equation4, 'purple');
      if (showEquation5) drawGraphEquation(plot, equation5, 'gray');
    }

    void drawGraphEquation(plot, expression, color) {
      document.querySelector('#plot').innerHtml = '';

      if (expression != "'Invalid function'" && !xmin.isNaN && !xmax.isNaN && xmin < xmax) {
        invalidFunction = false;
        Mathexp.Parser parser = new Mathexp.Parser();
        Mathexp.Expression exp = parser.parse(expression);
        Mathexp.ContextModel cm = new Mathexp.ContextModel();
        Mathexp.Variable x = new Mathexp.Variable('x');
        function f(d) {
          cm.bindVariable(x, new Mathexp.Number(d));
          double result =  exp.evaluate(Mathexp.EvaluationType.REAL, cm);
          if (result.isNaN) {
            return 0;
          } else if (result.isInfinite && result < 0) {
            return -25;
          } else if (result.isInfinite && result > 0) {
            return 25;
          } else {
            return result;
          }
        }

        List<double> data = new List<double>();
        for(double i = xmin, step = (xmax - xmin) / fineness; i < xmax; i += step) {
          data.add({'x': i, 'y': f(i) });
        }

        Map parameters = {
          'title': title,
          'xlabel': xlabel,
          'ylabel': ylabel,
          'xlim': [xmin - (xmax - xmin) / 16,
            xmax + (xmax - xmin) / 16] };


        if (expression.indexOf('x') < 0) {
          cm.bindVariable(x, new Mathexp.Number(0));
          double result =  exp.evaluate(Mathexp.EvaluationType.REAL, cm);
          if (result < -10) {
            parameters['ylim'] = [result, 10];
          } else if (result > 10) {
            parameters['ylim'] = [-10, result];
          } else {
            parameters['ylim'] = [-10, 10];
          }
        }
        plot.callMethod('xkcd', ['#plot', new JsObject.jsify(parameters)]);
        plot.callMethod('plot', [new JsObject.jsify(data),new JsObject.jsify({'stroke': color})]);
        plot.callMethod('draw');

        for (int i = xmin; i < xmax; i++) {
          cm.bindVariable(x, new Mathexp.Number(i));
          double result =  exp.evaluate(Mathexp.EvaluationType.REAL, cm);
          if (result.isNaN || result.isInfinite) {
            invalidFunction = true;
            warning = 'Some part of the equation is invalid along the domain you chose';
            break;
          }
        }

        print('[Graph Equation] ' + expression);
      } else {
        invalidFunction = true;
        warning = 'Sorry, invalid function';
        print('[Invalid Function] ' + expression);
      }
    }
  }

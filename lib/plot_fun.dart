library plot_fun_controller;

import 'dart:html';
import 'package:angular/angular.dart';
import 'package:math_expressions/math_expressions.dart' as Mathexp;
import 'package:plotfun/xkcd_plot.dart';
import 'dart:svg' show SvgElement;

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
    double fineness = 100.0;
    bool showEquation2 = false;
    bool showEquation3 = false;
    bool showEquation4 = false;
    bool showEquation5 = false;
    bool invalidFunction = false;
    String warning;
    
    //Variables
    DivElement plotElement = document.querySelector('#plot');

    void morePlots() {
      if (showEquation4 == true) showEquation5 = true;
      if (showEquation3 == true) showEquation4 = true;
      if (showEquation2 == true) showEquation3 = true;
      showEquation2 = true;
    }

    void drawGraph() {
      XkcdPlot plot = new XkcdPlot();
      drawGraphEquation(plot, equation, 'steelBlue');
      if (showEquation2) drawGraphEquation(plot, equation2, 'red');
      if (showEquation3) drawGraphEquation(plot, equation3, 'green');
      if (showEquation4) drawGraphEquation(plot, equation4, 'purple');
      if (showEquation5) drawGraphEquation(plot, equation5, 'gray');
    }

    void drawGraphEquation(plot, expression, color) {
      if (expression != "'Invalid function'" && !xmin.isNaN && !xmax.isNaN && xmin < xmax) {
        invalidFunction = false;
        Mathexp.Parser parser = new Mathexp.Parser();
        Mathexp.Expression exp = parser.parse(expression);
        Mathexp.ContextModel cm = new Mathexp.ContextModel();
        Mathexp.Variable x = new Mathexp.Variable('x');
        double f(d) {
          cm.bindVariable(x, new Mathexp.Number(d));
          double result =  exp.evaluate(Mathexp.EvaluationType.REAL, cm);
          if (result.isNaN) {
            return 0.0;
          } else if (result.isInfinite && result < 0) {
            return -25.0;
          } else if (result.isInfinite && result > 0) {
            return 25.0;
          } else {
            return result;
          }
        }

        List<List<double>> data = new List<List<double>>();
        for(double i = xmin.toDouble(), step = (xmax - xmin) / fineness;
            i < xmax; i += step) {
          data.add([i, f(i)]);
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
        plot.xkcd(parameters);
        plot.plot(data, {'stroke': color});
        SvgElement graph = plot.draw();
        plotElement.innerHtml = '';
        plotElement.nodes.add(graph);
        
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

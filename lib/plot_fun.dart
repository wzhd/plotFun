library plot_fun_controller;

import 'dart:html';
import 'package:angular/angular.dart';
import 'package:plotfun/xkcd_plot.dart';

@NgController(
    selector: '[plot-fun]',
    publishAs: 'ctrl')
class PlotFunController {
  //variables
  String xlabel = 'Time of Day';
  String ylabel = 'Awesomeness';
  String title = 'The Awesome Graph';
  List<Equation> equations = new List<Equation>();
  int xmin = -10;
  int xmax = 10;
  double fineness = 100.0;

  XkcdPlot plotter = new XkcdPlot(document.querySelector('#plot'));

  PlotFunController() {
    equations.add(new Equation('sin(x)'));
    drawGraph();
  }

  void morePlots() {
    equations.add(new Equation());
  }

  void removePlot(int index) {
    equations.removeAt(index);
    plotter.removeEquationAt(index);
    drawGraph();
  }

  void drawGraph() {
    Map param = {
      'xlabel': xlabel,
      'ylabel': ylabel,
      'xmin': xmin,
      'xmax': xmax,
      'fineness': fineness
      };
    plotter.drawGraphEquation(equations, param);
  }
}

class Equation {
  String expression;

  Equation([this.expression]);
}
library plot_fun_controller;

import 'dart:html';
import 'package:angular/angular.dart';
import 'package:plotfun/xkcd_plot.dart';

@NgController(
    selector: '[plot-fun]',
    publishAs: 'ctrl')
class PlotFunController {
  //variables
  String title;
  String xlabel;
  String ylabel;
  List<Equation> equations = new List<Equation>();
  int xmin = -10;
  int xmax = 10;
  double fineness = 100.0;
  String warning;

  XkcdPlot ploter = new XkcdPlot(document.querySelector('#plot'));

  PlotFunController() {
    equations.add(new Equation());
  }

  void morePlots() {
    equations.add(new Equation());
  }

  void removePlot(int index) {
    equations.removeAt(index);
    ploter.removeEquationAt(index);
    drawGraph();
  }

  void drawGraph() {
    Map param = {
      'title': title,
      'xlabel': xlabel,
      'ylabel': ylabel,
      'xmin': xmin,
      'xmax': xmax,
      'fineness': fineness
      };
    warning = ploter.drawGraphEquation(equations, param);
  }
}

class Equation {
  String expression;
}
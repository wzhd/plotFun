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
    String equation;
    int xmin = -10;
    int xmax = 10;
    double fineness = 100.0;
    String warning;

    XkcdPlot ploter = new XkcdPlot(document.querySelector('#plot'));

    PlotFunController() {
    }

    void morePlots() {
    }

    void drawGraph() {
      Map param = {
        'title': title,
        'xlabel': xlabel,
        'ylabel': ylabel,
        'xmin': xmin,
        'xmax': xmax,
        'fineness': fineness,
        'xlim': [xmin - (xmax - xmin) / 16,
          xmax + (xmax - xmin) / 16] };
      List equations = [equation];
      warning = ploter.drawGraphEquation(equations, param);
    }
  }

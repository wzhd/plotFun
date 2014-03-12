library plot_fun_controller;

import 'package:angular/angular.dart';
import 'package:plotfun/src/util.dart';
import 'package:plotfun/src/eval_expr.dart';
import 'package:plotfun/src/xinterp.dart';

@NgController(
    selector: '[plot-fun]',
    publishAs: 'ctrl')
class PlotFunController {
  // Parameters
  String xLabel = 'Time of Day';
  String yLabel = 'Awesomeness';
  String title = 'The Awesome Graph';
  double xmin = -10.0;
  double xmax = 10.0;
  double fineness = 100.0;
  int width = 600;
  int height = 300;
  int margin = 20;

  // Graph data
  List<Equation> equations = new List<Equation>();
  List<String> axes = new List<String>();
  double xLabelX;
  double xLabelY;
  double yLabelX;
  double yLabelY;

  PlotFunController() {
    addPlot();
    equations[0].expression = 'sin(x)';
    updateEquation(equations[0]);
  }

  void addPlot() {
    List<String> _colours = ['steelBlue', 'red', 'green', 'purple', 'gray'];
    String colour = _colours[equations.length % _colours.length];
    equations.add(new Equation(colour: colour));
  }

  void removePlot(int index) {
    equations.removeAt(index);
  }

  void _evalEquation(Equation equation) {
    Map result = evalExpr(equation.expression, xmin, xmax, fineness);
    equation.dataPoints = result['points'];
    equation.yMin = result['range'][0];
    equation.yMax = result['range'][1];
  }

  void updateEquation(Equation equation) {
    _evalEquation(equation);
    _drawGraph();
  }

  void updateAllEquations() {
    for (Equation eq in equations) {
      _evalEquation(eq);
    }
    _drawGraph();
  }

  void _drawGraph() {
    // Do linear scaling to convert coordinate system
    LinearScale xscale = new LinearScale();
    LinearScale yscale = new LinearScale();
    // Calculate domain and range
    List<double> xlim = [xmin - (xmax - xmin) / 16,
                         xmax + (xmax - xmin) / 16];
    List<double> ylim = [equations[0].yMin, equations[0].yMax];
    for (Equation eq in equations) {
      if (eq.yMin < ylim[0])
        ylim[0] = eq.yMin;
      if (eq.yMax > ylim[1])
        ylim[1] = eq.yMax;
    }
    ylim = [ylim[0] - (ylim[1] - ylim[0]) / 16,
            ylim[1] + (ylim[1] - ylim[0]) / 16];
    xscale..domain = xlim
          ..range = [0, width];
    yscale..domain = ylim
          ..range = [height, 0];

    void drawAxes() {
      int arrowSize = 12;
      double arrowAspect = 0.4;
      int arrowOffset = 6;

      axes.clear();
      // Compute the zero points where the axes will be drawn.
      double x0 = xscale.scale(0);
      double y0 = yscale.scale(0);

      axes.add(xinterp([[0, y0], [width, y0]])); // X Axis
      axes.add(xinterp([[x0, 0], [x0, height]])); // Y Axis

      // Laboriously draw some arrows at the ends of the axes.
      double aa = arrowAspect * arrowSize;
      int o = arrowOffset;
      int s = arrowSize;

      axes.add(xinterp([[width - s + o, y0 + aa], [width + o, y0], [width - s + o, y0 - aa]]));
      axes.add(xinterp([[x0 + aa, s - o], [x0, -o], [x0 - aa, s - o]]));

      // Labels
      xLabelX = (width - s).toDouble();
      xLabelY = y0 + aa;
      yLabelX = aa;
      yLabelY = x0;
    }
    drawAxes();

    for (Equation eq in equations) {
      List<List<double>> linearScaled = new List<List<double>>();
      for (List<double> point in eq.dataPoints) {
        linearScaled.add([xscale.scale(point[0]),
                          yscale.scale(point[1])]);
      }
      eq.line = xinterp(linearScaled);
    }
  }
}

class Equation {
  String expression;
  double yMax;
  double yMin;
  List<List<double>> dataPoints;
  String line = "M0,0"; // Make the d attribute valid before this is computed
  String colour;

  Equation({String expression, String colour}) {
    this.expression = expression;
    this.colour = colour;
  }
}
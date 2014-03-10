import 'dart:html';
import 'dart:svg';
import 'package:math_expressions/math_expressions.dart' as Mathexp;
import 'package:plotfun/src/util.dart';
import 'package:plotfun/src/xinterp.dart';

class XkcdPlot {

  // Default parameters.
  int width = 600;
  int height = 300;
  int margin = 20;
  String xlabel;
  String ylabel;
  int arrowSize = 12;
  double arrowAspect = 0.4;
  int arrowOffset = 6;
  List<double> xlim;
  List<double> ylim;

  // Elements
  SvgElement svgElement;
  GElement gElement;
  List<GElement> equationPlots = new List<GElement>();

  // Plot elements.
  LinearScale xscale = new LinearScale();
  LinearScale yscale = new LinearScale();

  // Plotting functions.
  List<Map> elements = new List<Map>();

  // The XKCD object itself.
  XkcdPlot(DivElement plotDiv) {
    svgElement = new SvgElement.tag('svg');
    svgElement.attributes['width'] = (width + 2 * margin).toString();
    svgElement.attributes['height'] = (height + 2 * margin).toString();

    gElement = new GElement();
    svgElement.append(gElement);
    gElement.attributes['transform'] = 'translate(' + margin.toString() + ', ' + margin.toString() + ')';

    plotDiv.append(svgElement);
  }

  // Do the render.
  void draw() {

    // Compute the zero points where the axes will be drawn.
    double x0 = xscale.scale(0);
    double y0 = yscale.scale(0);

    // Draw the axes.
    PathElement xAxis = new PathElement();
    xAxis.attributes['class'] = 'x axis';
    xAxis.attributes['d'] = xinterp([[0, y0], [width, y0]]);
    gElement.append(xAxis);
    PathElement yAxis = new PathElement();
    yAxis.attributes['class'] = 'y axis';
    yAxis.attributes['d'] = xinterp([[x0, 0], [x0, height]]);
    gElement.append(yAxis);

    // Laboriously draw some arrows at the ends of the axes.
    double aa = arrowAspect * arrowSize;
    int o = arrowOffset;
    int s = arrowSize;

    PathElement xAxisArrow0 = new PathElement();
    xAxisArrow0.attributes['class'] = 'x axis arrow';
    xAxisArrow0.attributes['d'] = xinterp([[width - s + o, y0 + aa], [width + o, y0], [width - s + o, y0 - aa]]);
    gElement.append(xAxisArrow0);

    PathElement yAxisArrow0 = new PathElement();
    yAxisArrow0.attributes['class'] = 'y axis arrow';
    yAxisArrow0.attributes['d'] = xinterp([[x0 + aa, s - o], [x0, -o], [x0 - aa, s - o]]);
    gElement.append(yAxisArrow0);

    for (int i = 0, l = elements.length; i < l; ++i) {
      var e = elements[i];
      GElement plot = lineplot(e['data'], e['opts']);
      equationPlots.add(plot);
      gElement.append(plot);
    }

    // Add some axes labels.
    TextElement xLabel = new TextElement();
    xLabel.attributes = {
      'class': 'x label',
      'text-anchor': 'end',
      'x': (width - s).toString(),
      'y': (y0 + aa).toString(),
      'dy': '.75em'
    };
    xLabel.innerHtml = xlabel;
    gElement.append(xLabel);
    TextElement yLabel = new TextElement();
    yLabel.attributes = {
      'class': 'y label',
      'text-anchor': 'end',
      'x': (aa).toString(),
      'y': (x0).toString(),
      'dy': '-.75em',
      'transform': 'rotate(-90)'
    };
    yLabel.innerHtml = ylabel;
    gElement.append(yLabel);
  }

  void removeEquationAt(int index) {
    elements.removeAt(index);
    equationPlots[index].remove();
    equationPlots.removeAt(index);
  }

  void removeAllEquations() {
    for (int i = equationPlots.length - 1; i >= 0; i--) {
      removeEquationAt(i);
    }
    gElement.innerHtml = '';
  }

  void drawGraphEquation(List equations, Map param) {
    List<String> colours = ['steelBlue', 'red', 'green', 'purple', 'gray'];
    int xmin, xmax;
    double fineness;
    ylim = [double.INFINITY, double.NEGATIVE_INFINITY];

    if (param['xlabel'] != null) xlabel = param['xlabel'];
    if (param['ylabel'] != null) ylabel = param['ylabel'];
    if (param['width'] != null) width = param['width'];
    if (param['height'] != null) height = param['height'];
    if (param['ylim'] != null) ylim = param['ylim'];
    if (param['fineness'] != null) fineness = param['fineness'];

    if (param['xmin'] != null) xmin = param['xmin'];
    if (param['xmax'] != null) xmax = param['xmax'];
    xlim = [xmin - (xmax - xmin) / 16,
             xmax + (xmax - xmin) / 16];

    if (xmin.isNaN || xmax.isNaN || xmin >= xmax) {
      print('[Invalid Functions] ' + equations.fold('', (value, element) => value + element.expression.toString() + ';'));
    }

    removeAllEquations();
    // An array of equations that each have points that each have coordinates
    List<List<List<double>>> equationsPoints = new List<List<List<double>>>();
    for(int i = 0; i < equations.length; i++) {
      String equation = equations[i].expression;
      Mathexp.Parser parser = new Mathexp.Parser();
      Mathexp.Expression exp = parser.parse(equation);
      Mathexp.ContextModel cm = new Mathexp.ContextModel();
      Mathexp.Variable x = new Mathexp.Variable('x');
      double f(d) {
        cm.bindVariable(x, new Mathexp.Number(d));
        double result =  exp.evaluate(Mathexp.EvaluationType.REAL, cm);
        if (result.isNaN || result.isInfinite) {
          return double.NAN;
        } else {
          return result;
        }
      }

      List<List<double>> oneEquationPoints = new List<List<double>>();
      for(double i = xmin.toDouble(), step = (xmax - xmin) / fineness;
          i < xmax; i += step) {
        double value = f(i);
        if (!value.isNaN) {
          oneEquationPoints.add([i, value]);
          if (param['ylim'] == null) { //no y limit explicitly set
            if (value < ylim[0])
              ylim[0] = value;
            if (value > ylim[1])
              ylim[1] = value;
          }
        }
      }
      equationsPoints.add(oneEquationPoints);
    }

    // Make some room
    ylim[0] = ylim[0] - (ylim[1] - ylim[0]) / 16;
    ylim[1] = ylim[1] + (ylim[1] - ylim[0]) / 16;

    // Set the axes limits.
    xscale..domain = xlim
      ..range = [0, width];
    yscale..domain = ylim
      ..range = [height, 0];

    for(int i = 0; i < equationsPoints.length; i++) {
      plot(equationsPoints[i], {'stroke': colours[i % colours.length]});
    }
    draw();

    print('[Graph Equation] ' + equations.fold('', (value, element) => value + element.expression.toString() + ';'));
  }

  // Adding plot elements.
   void plot(data, opts) {
    // Add the plotting function.
    List<List<double>> linearScaled = new List<List<double>>();
    for (int i = 0; i < data.length; i++) {
      linearScaled.add([xscale.scale(data[i][0]), yscale.scale(data[i][1])]);
    }
    elements.add({
    'data': linearScaled,
    'opts': opts
    });
  }

  // Plot styles.
  GElement lineplot(data, opts) {
    double strokeWidth = _get(opts, 'stroke-width', 3.0);
    String color = _get(opts, 'stroke', 'steelblue');

    PathElement bgPath = new PathElement();
    bgPath.attributes = {
      'd': xinterp(data),
      'stroke': 'white',
      'stroke-width': (2 * strokeWidth).toString() + 'px',
      'fill': 'none',
      'class': 'bgline'
    };

    PathElement linePath = new PathElement();
    linePath.attributes = {
      'd': xinterp(data),
      'stroke': color,
      'stroke-width': strokeWidth.toString() + 'px',
      'fill': 'none'
    };

    GElement line = new GElement();

    line.append(bgPath);
    line.append(linePath);

    return line;
  }

  // Get a value from an object or return a default if that doesn't work.
  Object _get(d, k, def) {
    if (d == null) return def;
    if (d[k] == null) return def;
    return d[k];
  }
}

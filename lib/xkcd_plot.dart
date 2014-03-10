import 'dart:html';
import 'dart:svg';
import 'dart:math' as Math;
import 'package:math_expressions/math_expressions.dart' as Mathexp;
import 'package:plotfun/util.dart';

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
  double magnitude = 1.5;
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

  // XKCD-style line interpolation
  String xinterp(points) {
    // Compute the distance between each point and its predecessor
    List<int> distances = new List<int>(); // number of points is int anyway
    for (int i = 0; i < points.length; i++) {
      if (i == 0) distances.add(0);
      else {
      num xd = points[i][0] - points[i - 1][0];
      num yd = points[i][1] - points[i - 1][1];
      distances.add(Math.sqrt(xd * xd + yd * yd).toInt());
      }
    }

    // Re-sample the line. So that it has more points
    List<List<num>> resampled = new List<List<double>>();
    for(int i = 1; i < distances.length; i++) {
      int pointsNum = Math.max(3, distances[i] ~/ 2);
      num x = points[i - 1][0];
      num xd = (points[i][0] - points[i - 1][0]) / (pointsNum - 1);
      num y = points[i - 1][1];
      num yd = (points[i][1] - points[i - 1][1]) / (pointsNum - 1);
      for (int j = 0; j < pointsNum - 1; ++j) {
        resampled.add([x, y]);
        x += xd;
        y += yd;
      }
    }
    resampled.add([points[points.length - 1][0], points[points.length - 1][1]]);

    // Compute the gradients.
    List<List<num>> gradients = new List<List<double>>();
    for(int i = 0; i < resampled.length; i++) {
      if (i == 0)
        gradients.add([resampled[1][0] - resampled[0][0],
                       resampled[1][1] - resampled[0][1]]);
      else if (i == resampled.length - 1)
        gradients.add([resampled[i][0] - resampled[i - 1][0],
                       resampled[i][1] - resampled[i - 1][1]]);
      else
        gradients.add([resampled[i + 1][0] - resampled[i - 1][0],
                       resampled[i + 1][1] - resampled[i - 1][1]]);
    }

    // Normalize the gradient vectors to be unit vectors.
    for(int i = 0; i < gradients.length; i++) {
      List<num> d = gradients[i];
      double len = Math.sqrt(d[0] * d[0] + d[1] * d[1]);
      gradients[i] = [d[0] / len, d[1] / len];
    }

    List<num> randNums = new List<double>();
    RandomNormal rand = new RandomNormal();
    for(int i = 0; i < resampled.length; i++) {
      randNums.add(rand.next());
    }

    // Generate some perturbations.
    List perturbations = smooth(randNums, 3);

    // Add in the perturbations and re-scale the re-sampled curve.
    String result = 'M';
    for (int i = 0; i < resampled.length; i++){
      List<num> data = resampled[i];
      num pert = perturbations[i];
      List<num> grad = gradients[i];
      result = result + (data[0] + magnitude * grad[1] * pert).toString() + ',';
      result = result + (data[1] - magnitude * grad[0] * pert).toString();
      if (i != resampled.length - 1)
        result = result + 'L';
    }

    return result;
  }

  // Smooth some data with a given window size.
  List<double> smooth(d, w) {
    List<double> result = new List<double>();
    for (int i = 0; i < d.length; ++i) {
      int mn = Math.max(0, i - 5 * w);
      int mx = Math.min(d.length - 1, i + 5 * w);
      double s = 0.0;
      result.add(0.0);
      for (int j = mn; j < mx; ++j) {
        double wd = Math.exp(-0.5 * (i - j) * (i - j) / w / w);
        result[i] += wd * d[j];
        s += wd;
      }
      result[i] /= s;
    }
    return result;
  }

  // Get a value from an object or return a default if that doesn't work.
  Object _get(d, k, def) {
    if (d == null) return def;
    if (d[k] == null) return def;
    return d[k];
  }
}

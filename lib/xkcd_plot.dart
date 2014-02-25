// Original Author: Dan Foreman-Mackey http://dan.iel.fm/xkcd/
// Customized by: Kevin Xu https://github.com/imkevinxu
// Rewritten in dart by: Zihao Wang https://github.com/wzhd

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
  int arrowSize = 12;
  double arrowAspect = 0.4;
  int arrowOffset = 6;
  double magnitude = 0.003;
  String xlabel = 'Time of Day';
  String ylabel = 'Awesomeness';
  String title = 'The Awesome Graph';
  List<double> xlim;
  List<double> ylim;
  SvgElement svgElement;
  GElement gElement;

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
  SvgElement draw() {

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
      lineplot(e['data'], e['opts']);
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

    return svgElement;
  }

  String drawGraphEquation(List<Map<String, String>> equations, Map param) {
    List<String> colours = ['steelBlue', 'red', 'green', 'purple', 'gray'];
    String warning = '';
    int xmin, xmax;
    double fineness;
    if (param['xmin'] != null) xmin = param['xmin'];
    if (param['xmax'] != null) xmax = param['xmax'];
    if (param['title'] != null) title = param['title'];
    if (param['xlabel'] != null) xlabel = param['xlabel'];
    if (param['ylabel'] != null) ylabel = param['ylabel'];
    if (param['width'] != null) width = param['width'];
    if (param['height'] != null) height = param['height'];
    if (param['xlim'] != null) xlim = param['xlim'];
    if (param['ylim'] != null) ylim = param['ylim'];
    if (param['fineness'] != null) fineness = param['fineness'];

    if (xmin.isNaN || xmax.isNaN || xmin >= xmax) {
      print('[Invalid Functions] ' + equations.toString());
      return('Sorry, invalid function');
    }

    for(int i = 0; i < equations.length; i++) {
      String equation = equations[i]['expression'];
      Mathexp.Parser parser = new Mathexp.Parser();
      Mathexp.Expression exp = parser.parse(equation);
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

      if (equation.indexOf('x') < 0) {
        cm.bindVariable(x, new Mathexp.Number(0));
        double result =  exp.evaluate(Mathexp.EvaluationType.REAL, cm);
        if (result < -10) {
          ylim = [result, 10];
        } else if (result > 10) {
          ylim = [-10, result];
        } else {
          ylim = [-10, 10];
        }
      }

      for (int j = xmin; j < xmax; j++) {
        cm.bindVariable(x, new Mathexp.Number(j));
        double result =  exp.evaluate(Mathexp.EvaluationType.REAL, cm);
        if (result.isNaN || result.isInfinite) {
          warning = 'Some part of the equation is invalid along the domain you chose';
          break;
        }
      }
      plot(data, {'stroke': colours[i % colours.length]});
    }
    draw();

    print('[Graph Equation] ' + equations.toString());
    return(warning);
  }

  // Adding plot elements.
   void plot(data, opts) {
    double x(d) { return d[0]; };
    double y(d) { return d[1]; };
    double cx(d) { return xscale.scale(x(d)); };
    double cy(d) { return yscale.scale(y(d)); };

    List<double> xl = extent(data, x);
    List<double> yl = extent(data, y);

    // Rescale the axes.
    xlim = xlim == null ? xl : xlim;
    xlim[0] = Math.min(xlim[0], xl[0]);
    xlim[1] = Math.max(xlim[1], xl[1]);

    ylim = ylim == null ? yl : ylim;
    ylim[0] = Math.min(ylim[0], yl[0]);
    ylim[1] = Math.max(ylim[1], yl[1]);
    ylim[0] = ylim[0] - (ylim[1] - ylim[0]) / 16;
    ylim[1] = ylim[1] + (ylim[1] - ylim[0]) / 16;

    // Set the axes limits.
    xscale..domain = xlim
      ..range = [0, width];
    yscale..domain = ylim
      ..range = [height, 0];
    
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
  void lineplot(data, opts) {
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
    gElement.append(bgPath);

    PathElement linePath = new PathElement();
    linePath.attributes = {
      'd': xinterp(data),
      'stroke': color,
      'stroke-width': strokeWidth.toString() + 'px',
      'fill': 'none'
    };
    gElement.append(linePath);
  }

  // XKCD-style line interpolation. Roughly based on:
  //    jakevdp.github.com/blog/2012/10/07/xkcd-style-plots-in-matplotlib
  String xinterp(points) {
    // Scale the data.
    List<double> lengths = [xscale.scale(xlim[1]) - xscale.scale(xlim[0]),
                            yscale.scale(ylim[1]) - yscale.scale(ylim[0])];
    List<double> origin = [xscale.scale(xlim[0]), yscale.scale(ylim[0])];
    List<List<double>> scaled = new List<List<double>>();
    for (int i = 0; i < points.length; i++) {
      List<double> pt = points[i];
      scaled.add([(pt[0] - origin[0]) / lengths[0], (pt[1] - origin[1]) / lengths[1]]);
    }

    // Compute the distance between each point and its predecessor
    List<double> distances = new List<double>();
    for (int i = 0; i < scaled.length; i++) {
      if (i == 0) distances.add(0.0);
      else {
      double xd = scaled[i][0] - scaled[i - 1][0];
      double yd = scaled[i][1] - scaled[i - 1][1];
      distances.add(Math.sqrt(xd * xd + yd * yd));
      }
    }
    double lineLength = distances.reduce((value, element) { return value + element; });

    // Choose the number of interpolation points based on this distance.
    int N = (200 * lineLength).round();

    // Re-sample the line.
    List<List<double>> resampled = new List<List<double>>();
    for(int i = 1; i < distances.length; i++) {
      int n = Math.max(3, (distances[i] / lineLength * N).round());
      double x = scaled[i - 1][0];
      double xd = (scaled[i][0] - scaled[i - 1][0]) / (n - 1);
      double y = scaled[i - 1][1];
      double yd = (scaled[i][1] - scaled[i - 1][1]) / (n - 1);
      for (int j = 0; j < n; ++j) {
        resampled.add([x, y]);
        x += xd;
        y += yd;
      }
    }

    // Compute the gradients.
    List<List<double>> gradients = new List<List<double>>();
    for(int i = 0; i < resampled.length; i++) {
      if (i == 0) 
        gradients.add([resampled[1][0] - resampled[0][0],
                resampled[1][1] - resampled[0][1]]);
      else if (i == resampled.length - 1)
        gradients.add([resampled[i][0] - resampled[i - 1][0], 
                       resampled[i][1] - resampled[i - 1][1]]);
      else
      gradients.add([0.5 * (resampled[i + 1][0] - resampled[i - 1][0]),
                     0.5 * (resampled[i + 1][1] - resampled[i - 1][1])]);
    }

    // Normalize the gradient vectors to be unit vectors.
    for(int i = 0; i < gradients.length; i++) {
      List<double> d = gradients[i];
      double len = Math.sqrt(d[0] * d[0] + d[1] * d[1]);
      gradients[i] = [d[0] / len, d[1] / len];
    }
    
    List<double> randomized = new List<double>();
    for(int i = 0; i < resampled.length; i++) {
      randomized.add((new RandomNormal().next(resampled[0][1])));
    }

    // Generate some perturbations.
    List perturbations = smooth(randomized, 3);

    // Add in the perturbations and re-scale the re-sampled curve.
    String result = 'M';
    for (int i = 0; i < resampled.length; i++){
      var d = resampled[i];
      double p = perturbations[i];
      List<double> g = gradients[i];
      result = result + ((d[0] + magnitude * g[1] * p) * lengths[0] + origin[0]).toString() + ',';
      result = result + ((d[1] - magnitude * g[0] * p) * lengths[1] + origin[1]).toString();
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

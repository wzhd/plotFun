library eval_expr;

import 'package:math_expressions/math_expressions.dart' as Mathexp;

Map evalExpr(String expr, double xmin, double xmax, double fineness) {
  Mathexp.Parser parser = new Mathexp.Parser();
  Mathexp.Expression exp = parser.parse(expr);
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

  List<List<double>> points = new List<List<double>>();
  List<double> range = [double.INFINITY, double.NEGATIVE_INFINITY];
  for(double i = xmin.toDouble(), step = (xmax - xmin) / fineness;
      i < xmax; i += step) {
    double value = f(i);
    if (!value.isNaN) {
      points.add([i, value]);
      if (value < range[0])
        range[0] = value;
      if (value > range[1])
        range[1] = value;
    }
  }
  return({
    'points': points,
    'range': range
  });
}
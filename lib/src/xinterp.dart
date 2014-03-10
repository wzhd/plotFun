library xinterp;

import 'dart:math' as Math;
import 'package:plotfun/src/util.dart';

// XKCD-style line interpolation
String xinterp(points) {

  double magnitude = 1.5;

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
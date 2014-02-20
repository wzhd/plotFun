import 'dart:math' as Math;

//find the min and max of data
List<num> extent(data, accessor) {
  num access(d) {
    if (d is num)
      return d;
    else
      return accessor(d);
  }
  num max = double.NEGATIVE_INFINITY;
  num min = double.INFINITY;
  for (int i = 0; i < data.length; i++) {
    var curr = data[i];
    if (access(curr) < min) {
      min = access(curr);
    }
    if (access(curr) > max) {
      max = access(curr);
    }
  }
  List<num> ext = [min, max];
  return ext;
}

class LinearScale {
  List<num> domain = [0, 1];
  List<num> range = [0, 1];

  double scale(num orig) {
    double rangeLength = (range[1] - range[0]).toDouble();
    double domainLength = (domain[1] - domain[0]).toDouble();
    double domainPos = (orig - domain[0]).toDouble();
    double result = range[0].toDouble() + rangeLength * domainPos / domainLength;
    return result;
  }
}

double randomNormal([double mean = 0.0, double deviation = 1.0]) {
  double rand = (new Math.Random()).nextDouble();
  return mean + 2 * deviation * rand - deviation; //TODO generate real normal distribution
}
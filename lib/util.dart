import 'dart:math' as Math;
import 'dart:collection' show Queue;

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

class RandomNormal {
  static Queue<double> _normalRand =  new Queue<double>();

  void newRandNormal() {
    double rand0 = (new Math.Random()).nextDouble();
    double rand1 = (new Math.Random()).nextDouble();
    double urand0 = Math.sqrt(-2 * Math.log(rand0)) * Math.cos(2 * Math.PI * rand1);
    double urand1 = Math.sqrt(-2 * Math.log(rand1)) * Math.cos(2 * Math.PI * rand0);
    _normalRand.add(urand0);
    _normalRand.add(urand1);
  }

  double next([double mean = 0.0, double deviation = 1.0]) {
    if (_normalRand.length == 0) newRandNormal();
    double result = (_normalRand.removeFirst()) * Math.sqrt(deviation) + mean;
    return result;
  }
}
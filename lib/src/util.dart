import 'dart:math' as Math;
import 'dart:collection' show Queue;

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
    num rand0 = (new Math.Random()).nextDouble();
    num rand1 = (new Math.Random()).nextDouble();
    num urand0 = Math.sqrt(-2 * Math.log(rand0)) * Math.cos(2 * Math.PI * rand1);
    num urand1 = Math.sqrt(-2 * Math.log(rand1)) * Math.cos(2 * Math.PI * rand0);
    _normalRand.add(urand0);
    _normalRand.add(urand1);
  }

  num next([num mean = 0.0, num deviation = 1.0]) {
    if (_normalRand.length == 0) newRandNormal();
    num result = (_normalRand.removeFirst()) * Math.sqrt(deviation) + mean;
    return result;
  }
}
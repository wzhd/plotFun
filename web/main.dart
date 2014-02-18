library plot_fun;

import 'package:angular/angular.dart';
import 'package:plotfun/plot_fun.dart';

class MyAppModule extends Module {
  MyAppModule() {
    type(PlotFunController);
  }
}

void main() {
  ngBootstrap(module: new MyAppModule());
}
library plot_fun;

// Temporary, please follow https://github.com/angular/angular.dart/issues/476
@MirrorsUsed(
  targets: const ['plot_fun_controller'],
  override: '*')
import 'dart:mirrors';

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
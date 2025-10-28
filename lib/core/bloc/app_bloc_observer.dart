import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';

class AppBlocObserver extends BlocObserver {
  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    if (event.toString().contains('Error') || event.toString().contains('Exception')) {
      developer.log('Bloc Event: ${bloc.runtimeType} -> $event', name: 'AppBlocObserver');
    }
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    if (transition.nextState.toString().contains('Error') ||
        transition.nextState.toString().contains('Failure')) {
      developer.log('Bloc Transition: ${bloc.runtimeType} -> ${transition.nextState}',
          name: 'AppBlocObserver');
    }
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    developer.log('Bloc Error: ${bloc.runtimeType} -> $error', name: 'AppBlocObserver', error: error, stackTrace: stackTrace);
  }
}

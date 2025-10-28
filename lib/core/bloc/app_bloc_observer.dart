import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';

class AppBlocObserver extends BlocObserver {
  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    developer.log('📨 Bloc Event: ${bloc.runtimeType} -> $event', name: 'BLoC');
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    developer.log(
      '🔄 Bloc Change: ${bloc.runtimeType} -> ${change.currentState} → ${change.nextState}',
      name: 'BLoC',
    );
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    developer.log(
      '⚡ Bloc Transition: ${bloc.runtimeType} -> ${transition.event} → ${transition.nextState}',
      name: 'BLoC',
    );
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    developer.log(
      '❌ Bloc Error: ${bloc.runtimeType} -> $error',
      name: 'BLoC',
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    developer.log('🆕 Bloc Created: ${bloc.runtimeType}', name: 'BLoC');
  }

  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
    developer.log('🗑️ Bloc Closed: ${bloc.runtimeType}', name: 'BLoC');
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:poc/app.dart';
import 'package:poc/core/photo/app_photo_cubit.dart';
import 'package:poc/features/classifier/classifier.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => AppPhotoCubit()),
        BlocProvider(create: (context) => ClassifierCubit()..initializeModel()),
      ],
      child: const App(),
    ),
  );
}

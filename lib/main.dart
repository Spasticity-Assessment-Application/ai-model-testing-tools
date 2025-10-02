import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:poc/app.dart';
import 'package:poc/core/photo/app_photo_cubit.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    BlocProvider(create: (context) => AppPhotoCubit(), child: const App()),
  );
}

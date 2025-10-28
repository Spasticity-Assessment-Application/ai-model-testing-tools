import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '/../../core/photo/app_photo_cubit.dart';
import 'package:poc/features/classifier/classifier.dart';

class ResultPage extends StatelessWidget {
  const ResultPage({super.key});

  String pourcentage(double p) => '${(p * 100).toStringAsFixed(1)}%';

  @override
  Widget build(BuildContext context) {
    final photoPath = context.select((AppPhotoCubit c) => c.currentPhotoPath);

    Widget photoPreview() {
      if (photoPath == null) return const SizedBox.shrink();
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(File(photoPath), height: 240, fit: BoxFit.cover),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Résultat de l'analyse")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: BlocBuilder<ClassifierCubit, ClassifierState>(
          builder: (context, state) {
            // En cours
            if (state is ClassifierLoading || state is ClassifierClassifying) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  photoPreview(),
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(),
                  const SizedBox(height: 8),
                  const Text('Analyse en cours…'),
                ],
              );
            }

            // Succès
            if (state is ClassifierResult) {
              final preds = state.result.predictions;
              if (preds.isEmpty) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    photoPreview(),
                    const SizedBox(height: 12),
                    const Text('Aucune prédiction.'),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Retour'),
                    ),
                  ],
                );
              }

              final top1 = preds.first;
              final others = preds
                  .skip(1)
                  .take(4)
                  .toList(); //on prend 4 autres possibilite

              return SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    photoPreview(),
                    const SizedBox(height: 16),

                    // meilleur possibility
                    Text(
                      top1.label,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: top1.confidence.clamp(0, 1),
                            minHeight: 10,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          pourcentage(top1.confidence),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),

                    // autres possibilite de classes
                    if (others.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Autres classes possibles',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: others.length,
                        separatorBuilder: (_, __) => const Divider(height: 12),
                        itemBuilder: (context, i) {
                          final p = others[i];
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text(p.label)),
                              Text(pourcentage(p.confidence)),
                            ],
                          );
                        },
                      ),
                    ],

                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Retour'),
                    ),
                  ],
                ),
              );
            }

            // Erreur
            if (state is ClassifierError) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  photoPreview(),
                  const SizedBox(height: 12),
                  Text(
                    'Erreur : ${state.message}',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Retour'),
                  ),
                ],
              );
            }

            // Initial / prêt
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                photoPreview(),
                const SizedBox(height: 12),
                const Text(
                  'Reclique sur "Analyze Photo" pour lancer la classification.',
                ), //si on a ce message, on fait retour arriere dans l'app et on re click analyse pour voir les resultats
              ],
            );
          },
        ),
      ),
    );
  }
}

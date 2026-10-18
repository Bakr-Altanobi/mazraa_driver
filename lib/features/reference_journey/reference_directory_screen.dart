import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mazraa_driver/features/reference_journey/reference_catalog.dart';

/// The onboarding/login screens are reached before authentication. This
/// directory exposes the other reference-backed, live-data driver services.
class DriverServicesDirectoryScreen extends StatelessWidget {
  const DriverServicesDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final services = ReferenceCatalog.screens
        .where((screen) => screen.number >= 3)
        .toList(growable: false);
    return Scaffold(
      appBar: AppBar(title: const Text('خدمات السائق')),
      body: ListView.separated(
        key: const Key('driverServicesDirectory'),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
        itemCount: services.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final spec = services[index];
          return Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              key: Key('driverService${spec.number}'),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              leading: SizedBox(
                width: 58,
                height: 58,
                child: spec.assets.isEmpty
                    ? const Icon(Icons.apps_rounded)
                    : Image.asset(
                        spec.assets.first.path,
                        fit: BoxFit.contain,
                        cacheWidth: 220,
                      ),
              ),
              title: Text(spec.titleAr),
              subtitle: Text(
                spec.unsupported.isEmpty
                    ? spec.descriptionAr
                    : 'بعض العناصر المرجعية لم يدعمها السيرفر بعد',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_left_rounded),
              onTap: () => context.push(spec.route),
            ),
          );
        },
      ),
    );
  }
}

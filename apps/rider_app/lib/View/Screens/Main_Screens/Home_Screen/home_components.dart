/// Home Screen Components
///
/// Reusable UI components for the shuttle tracking home screen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'home_providers.dart';
import 'home_logics.dart';

/// Route filter chips at the top of the screen
class RouteFilterChips extends ConsumerWidget {
  const RouteFilterChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routes = ref.watch(routesProvider);
    final selectedRoute = ref.watch(selectedRouteProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // "All Routes" chip
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('All Routes'),
              selected: selectedRoute == null,
              onSelected: (_) {
                HomeScreenLogics().selectRoute(ref, null);
              },
              backgroundColor: Colors.black54,
              selectedColor: Colors.blue,
              labelStyle: TextStyle(
                color: selectedRoute == null ? Colors.white : Colors.white70,
              ),
              checkmarkColor: Colors.white,
            ),
          ),
          // Route-specific chips
          ...routes.map((route) {
            final color = _parseColor(route.color);
            final isSelected = selectedRoute == route.id;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(route.name),
                selected: isSelected,
                onSelected: (_) {
                  HomeScreenLogics().selectRoute(ref, isSelected ? null : route.id);
                },
                backgroundColor: Colors.black54,
                selectedColor: color,
                labelStyle: const TextStyle(color: Colors.white),
                checkmarkColor: Colors.white,
                avatar: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _parseColor(String hexColor) {
    hexColor = hexColor.replaceFirst('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }
}

/// Bottom sheet showing nearest stop and ETA
class NearestStopSheet extends ConsumerWidget {
  const NearestStopSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nearestStop = ref.watch(nearestStopProvider);
    final eta = ref.watch(nearestStopEtaProvider);
    final vehicles = ref.watch(filteredVehiclesProvider);
    final isExpanded = ref.watch(bottomSheetExpandedProvider);

    return GestureDetector(
      onVerticalDragUpdate: (details) {
        if (details.delta.dy < -5) {
          ref.read(bottomSheetExpandedProvider.notifier).state = true;
        } else if (details.delta.dy > 5) {
          ref.read(bottomSheetExpandedProvider.notifier).state = false;
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        height: isExpanded ? 350 : 180,
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade600,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Nearest stop header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.directions_bus,
                      color: Colors.blue,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nearest Stop',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          nearestStop?.name ?? 'Locating...',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // ETA badge
                  if (eta != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '$eta',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'min',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade700,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'No ETA',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Active shuttles count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(
                    Icons.local_shipping,
                    color: Colors.grey,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${vehicles.length} shuttle${vehicles.length != 1 ? 's' : ''} active',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Expanded content - list of stops
            if (isExpanded) ...[
              const SizedBox(height: 16),
              const Divider(color: Colors.grey, height: 1),
              Expanded(
                child: Consumer(
                  builder: (context, ref, child) {
                    final stops = ref.watch(stopsProvider);
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: stops.length,
                      itemBuilder: (context, index) {
                        final stop = stops[index];
                        final isNearest = stop.id == nearestStop?.id;
                        return ListTile(
                          leading: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isNearest
                                  ? Colors.blue.withOpacity(0.2)
                                  : Colors.grey.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: isNearest ? Colors.blue : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            stop.name,
                            style: TextStyle(
                              color: isNearest ? Colors.white : Colors.grey,
                              fontWeight:
                                  isNearest ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                          trailing: isNearest
                              ? const Icon(Icons.near_me, color: Colors.blue)
                              : null,
                          onTap: () {
                            HomeScreenLogics().selectStop(ref, stop);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Vehicle info card (for expanded details)
class VehicleCard extends StatelessWidget {
  final VehiclePosition vehicle;

  const VehicleCard({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.directions_bus,
            color: Colors.blue,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'Shuttle ${vehicle.vehicleId.substring(0, 4)}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            vehicle.status.toUpperCase(),
            style: TextStyle(
              color: vehicle.status == 'active' ? Colors.green : Colors.orange,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (vehicle.speed != null) ...[
            const SizedBox(height: 4),
            Text(
              '${vehicle.speed!.toStringAsFixed(0)} km/h',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

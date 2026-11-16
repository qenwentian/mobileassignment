import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/item_model.dart';
import '../theme.dart';
import '../viewmodels/items_viewmodel.dart';
import '../viewmodels/nav_viewmodel.dart';

const _userDx = 0.5;
const _userDy = 0.88;

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = context.watch<ItemsViewModel>();
    final nav = context.watch<NavViewModel>();
    final selected = items.pinById(nav.selectedPinId);
    final here = selected == null ? <ItemModel>[] : items.itemsAt(selected.id);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Campus locations',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
          const Text('Demo campus map',
              style: TextStyle(color: AppColors.muted)),
          const SizedBox(height: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LayoutBuilder(builder: (_, c) {
                final w = c.maxWidth, h = c.maxHeight;
                return Stack(children: [
                  Positioned.fill(
                    child:
                        Image.asset('assets/campus_map.png', fit: BoxFit.fill),
                  ),
                  if (nav.routeVisible && selected != null)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _RoutePainter([
                          Offset(_userDx * w, _userDy * h),
                          Offset(_userDx * w, 0.45 * h),
                          Offset(selected.dx * w, 0.45 * h),
                          Offset(selected.dx * w, selected.dy * h),
                        ]),
                      ),
                    ),
                  Positioned(
                    left: _userDx * w - 8,
                    top: _userDy * h - 8,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                  for (final p in items.pins)
                    Positioned(
                      left: p.dx * w - 60,
                      bottom: (1 - p.dy) * h,
                      width: 120,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => nav.selectPin(p.id),
                        child: _PinMarker(
                          label: p.id,
                          active: p.id == nav.selectedPinId,
                          count: items.itemsAt(p.id).length,
                        ),
                      ),
                    ),
                ]);
              }),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: selected == null
                ? const Text('Tap a pin to see items turned in or lost there.',
                    style: TextStyle(color: AppColors.muted))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(selected.id,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(selected.room,
                          style: const TextStyle(color: AppColors.accent)),
                      const SizedBox(height: 6),
                      Text(
                        here.isEmpty
                            ? 'No items posted here yet.'
                            : here.map((i) => i.name).join(', '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: selected == null ? null : nav.showRoute,
            child: const Text('Preview Route'),
          ),
        ],
      ),
    );
  }
}

class _PinMarker extends StatelessWidget {
  const _PinMarker(
      {required this.label, required this.active, required this.count});
  final String label;
  final bool active;
  final int count;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.accent : AppColors.lost;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: active ? AppColors.accent : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600)),
      ),
      Stack(clipBehavior: Clip.none, children: [
        Icon(Icons.location_on, size: active ? 34 : 28, color: color),
        if (count > 0)
          Positioned(
            right: -4,
            top: 0,
            child: CircleAvatar(
              radius: 8,
              backgroundColor: Colors.white,
              child: Text('$count',
                  style: const TextStyle(color: Colors.black, fontSize: 10)),
            ),
          ),
      ]),
    ]);
  }
}

class _RoutePainter extends CustomPainter {
  _RoutePainter(this.route);
  final List<Offset> route;

  @override
  void paint(Canvas canvas, Size s) {
    final path = Path()..moveTo(route.first.dx, route.first.dy);
    for (final p in route.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    final dash = Paint()
      ..color = const Color(0xFF097AD2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (final m in path.computeMetrics()) {
      for (double d = 0; d < m.length; d += 16) {
        canvas.drawPath(m.extractPath(d, d + 9), dash);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RoutePainter old) => old.route != route;
}

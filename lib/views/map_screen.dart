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
          const Text('Found Items Map',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LayoutBuilder(builder: (_, c) {
                final w = c.maxWidth, h = c.maxHeight;
                return Stack(children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _MapPainter(
                        route: nav.routeVisible && selected != null
                            ? [
                                Offset(_userDx * w, _userDy * h),
                                Offset(selected.dx * w, _userDy * h),
                                Offset(selected.dx * w, selected.dy * h),
                              ]
                            : null,
                      ),
                    ),
                  ),
                  Positioned(
                    left: _userDx * w - 8,
                    top: _userDy * h - 8,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppColors.found,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                  for (final p in items.pins)
                    Positioned(
                      left: p.dx * w - 60,
                      top: p.dy * h - 46,
                      width: 120,
                      child: GestureDetector(
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
            child: const Text('Get Directions'),
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
        child: Text(active ? '$label Pin Active' : label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
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

class _MapPainter extends CustomPainter {
  _MapPainter({this.route});
  final List<Offset>? route;

  @override
  void paint(Canvas canvas, Size s) {
    canvas.drawRect(Offset.zero & s, Paint()..color = const Color(0xFF16202D));
    // River
    canvas.drawRect(Rect.fromLTWH(s.width * 0.9, 0, s.width * 0.1, s.height),
        Paint()..color = const Color(0xFF0C3B5C));
    // Quad
    canvas.drawOval(
        Rect.fromLTWH(s.width * 0.38, s.height * 0.05, s.width * 0.3, s.height * 0.18),
        Paint()..color = const Color(0xFF14532D).withValues(alpha: 0.55));
    // Roads
    final road = Paint()
      ..color = const Color(0xFF243247)
      ..strokeWidth = 14;
    canvas.drawLine(Offset(0, s.height * 0.75), Offset(s.width * 0.9, s.height * 0.75), road);
    canvas.drawLine(Offset(s.width * 0.5, 0), Offset(s.width * 0.5, s.height), road);
    canvas.drawLine(Offset(0, s.height * 0.42), Offset(s.width * 0.9, s.height * 0.42), road);

    final r = route;
    if (r == null) return;
    final path = Path()..moveTo(r.first.dx, r.first.dy);
    for (final p in r.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    final dash = Paint()
      ..color = AppColors.accent
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
  bool shouldRepaint(covariant _MapPainter old) => old.route != route;
}

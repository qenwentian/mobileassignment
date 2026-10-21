import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/item_model.dart';
import '../theme.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/items_viewmodel.dart';
import '../viewmodels/nav_viewmodel.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});
  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _location = TextEditingController();
  final _desc = TextEditingController();
  ItemStatus _status = ItemStatus.lost;
  String? _category;
  String? _building;
  // Simulated upload. To use the real camera/gallery, add `image_picker`
  // and store the picked file path here.
  bool _hasPhoto = false;
  bool _isPublishing = false;

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isPublishing || !_form.currentState!.validate()) return;
    final owner = context.read<AuthViewModel>().user;
    if (owner == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Log in before publishing a report.')),
      );
      return;
    }
    setState(() => _isPublishing = true);
    try {
      context.read<ItemsViewModel>().publish(
        owner: owner,
        status: _status,
        name: _name.text,
        category: _category!,
        buildingId: _building!,
        locationDetail: _location.text,
        description: _desc.text,
        hasPhoto: _hasPhoto,
      );
      _form.currentState!.reset();
      _name.clear();
      _location.clear();
      _desc.clear();
      setState(() {
        _status = ItemStatus.lost;
        _category = null;
        _building = null;
        _hasPhoto = false;
      });
      context.read<NavViewModel>().setIndex(0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Published. Your report is now in the feed.'),
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not publish report: $error')),
      );
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = context.watch<ItemsViewModel>();
    final lost = _status == ItemStatus.lost;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              lost ? 'Report Lost Item' : 'Report Found Item',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            SegmentedButton<ItemStatus>(
              segments: const [
                ButtonSegment(value: ItemStatus.lost, label: Text('Lost')),
                ButtonSegment(value: ItemStatus.found, label: Text('Found')),
              ],
              selected: {_status},
              onSelectionChanged: (s) => setState(() => _status = s.first),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Item Name *'),
              validator: (v) => items.validateRequired(v, 'the item name'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category *'),
              items: [
                for (final c in ItemsViewModel.reportCategories)
                  DropdownMenuItem(value: c, child: Text(c)),
              ],
              onChanged: (v) => setState(() => _category = v),
              validator: (v) => v == null ? 'Choose a category' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _building,
              decoration: const InputDecoration(labelText: 'Campus Building *'),
              items: [
                for (final p in items.pins)
                  DropdownMenuItem(value: p.id, child: Text(p.id)),
              ],
              onChanged: (v) => setState(() => _building = v),
              validator: (v) => v == null ? 'Choose a building' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _location,
              decoration: const InputDecoration(
                labelText: 'Last Seen Location *',
                suffixIcon: Icon(Icons.place_outlined),
              ),
              validator: (v) => items.validateRequired(v, 'the location'),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => setState(() => _hasPhoto = !_hasPhoto),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 100,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _hasPhoto ? AppColors.found : AppColors.border,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _hasPhoto
                          ? Icons.check_circle
                          : Icons.add_a_photo_outlined,
                      color: _hasPhoto ? AppColors.found : AppColors.muted,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _hasPhoto
                          ? 'Photo attached (tap to remove)'
                          : 'Tap to upload proof or reference photo',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _desc,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Description & Identifying Marks',
                alignLabelWithHint: true,
              ),
              validator: (v) => items.validateRequired(v, 'a description'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isPublishing ? null : _submit,
              child: Text(
                _isPublishing
                    ? 'Publishing...'
                    : (lost ? 'Publish Lost Report' : 'Publish Found Report'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

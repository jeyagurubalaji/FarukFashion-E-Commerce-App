import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/address_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';

class AddressesScreen extends StatelessWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final addr = context.watch<AddressProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Addresses'),
        actions: [
          IconButton(
            tooltip: 'Add address',
            icon: const Icon(Icons.add, color: AppColors.gold),
            onPressed: () => _openForm(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.black,
        icon: const Icon(Icons.add),
        label: const Text('Add address'),
      ),
      body: addr.items.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_off_outlined,
                      color: AppColors.textMuted, size: 48),
                  const SizedBox(height: 12),
                  const Text(
                    'No addresses saved',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _openForm(context),
                    child: const Text('Add your first address'),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: addr.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final a = addr.items[i];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: a.isDefault
                          ? AppColors.gold
                          : AppColors.gold.withOpacity(0.2),
                      width: a.isDefault ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              a.fullName,
                              style: const TextStyle(
                                color: AppColors.gold,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          if (a.isDefault)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.gold.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'DEFAULT',
                                style: TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(a.line1,
                          style: const TextStyle(color: AppColors.white)),
                      if (a.line2.trim().isNotEmpty)
                        Text(a.line2,
                            style: const TextStyle(color: AppColors.white)),
                      Text(
                        '${a.city}, ${a.state} - ${a.pincode}',
                        style: const TextStyle(color: AppColors.white),
                      ),
                      if (a.phone.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '📞 ${a.phone}',
                          style:
                              const TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          if (!a.isDefault)
                            TextButton(
                              onPressed: () => context
                                  .read<AddressProvider>()
                                  .setDefault(a.id),
                              child: const Text('Set default',
                                  style: TextStyle(color: AppColors.gold)),
                            ),
                          const Spacer(),
                          IconButton(
                            tooltip: 'Edit',
                            icon: const Icon(Icons.edit_outlined,
                                color: AppColors.gold, size: 20),
                            onPressed: () =>
                                _openForm(context, existing: a),
                          ),
                          IconButton(
                            tooltip: 'Delete',
                            icon: const Icon(Icons.delete_outline,
                                color: AppColors.error, size: 20),
                            onPressed: () => _confirmDelete(context, a),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, AddressItem a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete address?',
            style: TextStyle(color: AppColors.gold)),
        content: Text(a.line1,
            style: const TextStyle(color: AppColors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<AddressProvider>().remove(a.id);
    }
  }

  Future<void> _openForm(BuildContext context, {AddressItem? existing}) async {
    final user = context.read<AuthProvider>().user;
    final isEdit = existing != null;

    final nameCtrl = TextEditingController(
        text: existing?.fullName ?? user?.fullName ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final line1Ctrl = TextEditingController(text: existing?.line1 ?? '');
    final line2Ctrl = TextEditingController(text: existing?.line2 ?? '');
    final cityCtrl = TextEditingController(text: existing?.city ?? '');
    final stateCtrl = TextEditingController(text: existing?.state ?? '');
    final pinCtrl = TextEditingController(text: existing?.pincode ?? '');
    bool isDefault = existing?.isDefault ?? false;

    final formKey = GlobalKey<FormState>();

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (ctx, setModal) {
              return Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        isEdit ? 'Edit address' : 'Add address',
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _field(nameCtrl, 'Full name', required: true),
                      _field(phoneCtrl, 'Phone',
                          required: true, keyboard: TextInputType.phone),
                      _field(line1Ctrl, 'Address line 1', required: true),
                      _field(line2Ctrl, 'Address line 2 (optional)'),
                      _field(cityCtrl, 'City', required: true),
                      _field(stateCtrl, 'State', required: true),
                      _field(pinCtrl, 'Pincode',
                          required: true, keyboard: TextInputType.number),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Set as default',
                            style: TextStyle(color: AppColors.white)),
                        value: isDefault,
                        activeColor: AppColors.gold,
                        onChanged: (v) => setModal(() => isDefault = v),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          if (!formKey.currentState!.validate()) return;
                          Navigator.pop(ctx, true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: AppColors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          isEdit ? 'SAVE CHANGES' : 'SAVE ADDRESS',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );

    if (saved != true || !context.mounted) {
      nameCtrl.dispose();
      phoneCtrl.dispose();
      line1Ctrl.dispose();
      line2Ctrl.dispose();
      cityCtrl.dispose();
      stateCtrl.dispose();
      pinCtrl.dispose();
      return;
    }

    final item = AddressItem(
      id: existing?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      fullName: nameCtrl.text.trim(),
      phone: phoneCtrl.text.trim(),
      line1: line1Ctrl.text.trim(),
      line2: line2Ctrl.text.trim(),
      city: cityCtrl.text.trim(),
      state: stateCtrl.text.trim(),
      pincode: pinCtrl.text.trim(),
      isDefault: isDefault,
    );

    final provider = context.read<AddressProvider>();
    if (isEdit) {
      await provider.update(item);
    } else {
      await provider.add(item);
    }

    nameCtrl.dispose();
    phoneCtrl.dispose();
    line1Ctrl.dispose();
    line2Ctrl.dispose();
    cityCtrl.dispose();
    stateCtrl.dispose();
    pinCtrl.dispose();
  }

  Widget _field(
    TextEditingController c,
    String label, {
    bool required = false,
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: c,
        keyboardType: keyboard,
        style: const TextStyle(color: AppColors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.textSecondary),
          filled: true,
          fillColor: AppColors.cardBg,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
            : null,
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/finance_provider.dart';
import '../../models/models.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  void _showAddDialog(BuildContext context, String type) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Tambah Kategori ${type == 'income' ? 'Pemasukan' : 'Pengeluaran'}'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Nama kategori',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              await context.read<FinanceProvider>().addCategory(ctrl.text, type);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Kategori berhasil ditambahkan')),
                );
              }
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Kategori'),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: AppTheme.mintGreen,
          tabs: const [
            Tab(text: 'Pemasukan', icon: Icon(Icons.arrow_downward_rounded, size: 18)),
            Tab(text: 'Pengeluaran', icon: Icon(Icons.arrow_upward_rounded, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _CategoryList(type: 'income'),
          _CategoryList(type: 'expense'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final type = _tabCtrl.index == 0 ? 'income' : 'expense';
          _showAddDialog(context, type);
        },
        backgroundColor: AppTheme.deepBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _CategoryList extends StatelessWidget {
  final String type;

  const _CategoryList({required this.type});

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, fp, _) {
        final categories = type == 'income' ? fp.incomeCategories : fp.expenseCategories;
        final color = type == 'income' ? AppTheme.mintGreen : AppTheme.errorRed;

        if (categories.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.category_outlined, size: 52, color: AppTheme.medGrey),
                const SizedBox(height: 12),
                const Text('Belum ada kategori', style: TextStyle(color: AppTheme.darkGrey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: categories.length,
          itemBuilder: (ctx, i) {
            final cat = categories[i];
            final isProtected = cat.name == 'Admin' && type == 'expense';
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    type == 'income' ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                    color: color,
                    size: 18,
                  ),
                ),
                title: Text(cat.name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: isProtected
                    ? const Text('Kategori sistem — tidak dapat dihapus',
                        style: TextStyle(fontSize: 11, color: AppTheme.warningAmber))
                    : null,
                trailing: isProtected
                    ? const Icon(Icons.lock_outline_rounded, color: AppTheme.medGrey, size: 18)
                    : IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.medGrey),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: ctx,
                            builder: (dctx) => AlertDialog(
                              title: const Text('Hapus Kategori?'),
                              content: Text(
                                'Kategori "${cat.name}" akan dihapus. '
                                'Transaksi yang sudah ada tidak ikut terhapus.',
                              ),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(dctx, false),
                                    child: const Text('Batal')),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(dctx, true),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.errorRed),
                                  child: const Text('Hapus',
                                      style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true && ctx.mounted) {
                            final success = await ctx.read<FinanceProvider>()
                                .deleteCategory(cat.id!, type);
                            if (!success && ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(content: Text('Kategori ini tidak dapat dihapus')),
                              );
                            }
                          }
                        },
                      ),
              ),
            );
          },
        );
      },
    );
  }
}
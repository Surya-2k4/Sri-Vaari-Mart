import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:vaari/core/constants/app_colors.dart';
import '../viewmodel/admin_order_viewmodel.dart';
import '../viewmodel/admin_product_viewmodel.dart';
import '../model/admin_order_model.dart';
import '../../../core/utils/report_generator.dart';

class AdminDashboardView extends ConsumerStatefulWidget {
  const AdminDashboardView({super.key});

  @override
  ConsumerState<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends ConsumerState<AdminDashboardView> {
  String _selectedDuration = 'Weekly';
  final List<String> _durations = ['Daily', 'Weekly', 'Monthly'];

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(adminOrderViewModelProvider);
    final productsState = ref.watch(adminProductViewModelProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: ordersState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (orders) {
          final products = productsState.value ?? [];
          return _buildDashboardContent(orders, products);
        },
      ),
    );
  }

  Widget _buildDashboardContent(List<AdminOrderModel> orders, dynamic products) {
    final totalSales = orders.fold<double>(0, (sum, order) => sum + order.totalAmount);
    final totalOrders = orders.length;
    final pendingOrders = orders.where((o) => o.status.toLowerCase() == 'pending').length;
    
    // Today's Sales
    final now = DateTime.now();
    final todaySales = orders
        .where((o) => o.createdAt.day == now.day && o.createdAt.month == now.month && o.createdAt.year == now.year)
        .fold<double>(0, (sum, order) => sum + order.totalAmount);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 32),
          
          // Stats Grid
          _buildStatsGrid(totalSales, totalOrders, pendingOrders, todaySales),
          const SizedBox(height: 32),
          
          // Charts Section
          _buildChartsSection(orders),
          const SizedBox(height: 32),
          
          // Recent OrdersSection
          _buildRecentOrdersSection(orders),
          const SizedBox(height: 32),
          
          // Reports Section
          _buildReportsSection(orders),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final content = [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sales Overview',
                style: TextStyle(
                  fontSize: isMobile ? 24 : 32,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryBlack,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Real-time data insights',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
          if (isMobile) const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  DateFormat('MMM dd, yyyy').format(DateTime.now()),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
          ),
        ];

        return isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: content,
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: content,
              );
      },
    );
  }

  Widget _buildStatsGrid(double totalSales, int totalOrders, int pending, double todaySales) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 600;
        int crossAxisCount = constraints.maxWidth > 900 ? 4 : 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: isMobile ? 12 : 20,
          mainAxisSpacing: isMobile ? 12 : 20,
          childAspectRatio: isMobile ? 1.3 : 1.6,
          children: [
            _buildStatCard(
              'Total Revenue',
              '₹${NumberFormat('#,##,###').format(totalSales)}',
              Icons.account_balance_wallet,
              Colors.blue,
              isMobile,
            ),
            _buildStatCard(
              'Orders',
              '$totalOrders',
              Icons.shopping_cart,
              Colors.orange,
              isMobile,
            ),
            _buildStatCard(
              'Pending',
              '$pending',
              Icons.pending_actions,
              Colors.red,
              isMobile,
            ),
            _buildStatCard(
              'Today\'s Sales',
              '₹${NumberFormat('#,##,###').format(todaySales)}',
              Icons.trending_up,
              Colors.green,
              isMobile,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 18 : 24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 8 : 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: isMobile ? 18 : 24),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 10 : 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection(List<AdminOrderModel> orders) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 900) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _buildSalesBarChart(orders)),
              const SizedBox(width: 24),
              Expanded(flex: 1, child: _buildOrderStatusChart(orders)),
            ],
          );
        } else {
          return Column(
            children: [
              _buildSalesBarChart(orders),
              const SizedBox(height: 24),
              _buildOrderStatusChart(orders),
            ],
          );
        }
      },
    );
  }

  Widget _buildSalesBarChart(List<AdminOrderModel> orders) {
    // Logic to get last 7 days sales
    final List<BarChartGroupData> barGroups = [];
    final List<String> dayLabels = [];
    final now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final daySales = orders
          .where((o) => o.createdAt.day == day.day && o.createdAt.month == day.month && o.createdAt.year == day.year)
          .fold<double>(0, (sum, order) => sum + order.totalAmount);
      
      dayLabels.add(DateFormat('E').format(day));
      barGroups.add(
        BarChartGroupData(
          x: 6 - i,
          barRods: [
            BarChartRodData(
              toY: daySales,
              color: AppColors.primaryBlack,
              width: 16,
              borderRadius: BorderRadius.circular(4),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: 50000, // Max scale (will adjust dynamically in real app)
                color: Colors.grey.shade100,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Weekly Revenue',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: _selectedDuration,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                  items: _durations
                      .map(
                        (d) => DropdownMenuItem(
                          value: d,
                          child: Text(
                            d,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => _selectedDuration = val!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 50000,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.primaryBlack,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '₹${NumberFormat('#,###').format(rod.toY)}',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) => Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          dayLabels[val.toInt()],
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: barGroups,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOrdersSection(List<AdminOrderModel> orders) {
    final recentOrders = orders.take(5).toList();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Orders',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  // Index 2 is Orders in AdminPanelView
                  // However, we are inside a child. We can't easily change parent state here without a provider.
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (recentOrders.isEmpty)
            const Center(child: Text('No orders yet'))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentOrders.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final order = recentOrders[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    '#${order.id.substring(0, 8)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  subtitle: Text(
                    DateFormat('MMM dd, hh:mm a').format(order.createdAt),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '₹${order.totalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 12),
                      _buildStatusIndicator(order.status),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'pending': color = Colors.orange; break;
      case 'completed': color = Colors.green; break;
      case 'cancelled': color = Colors.red; break;
      default: color = Colors.blue;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildOrderStatusChart(List<AdminOrderModel> orders) {
    final Map<String, int> counts = {};
    for (var o in orders) {
      counts[o.status] = (counts[o.status] ?? 0) + 1;
    }

    final List<PieChartSectionData> sections = [];
    final statuses = counts.keys.toList();
    final colors = [Colors.blue, Colors.orange, Colors.green, Colors.red, Colors.purple];

    for (int i = 0; i < statuses.length; i++) {
       sections.add(
         PieChartSectionData(
           value: counts[statuses[i]]!.toDouble(),
           title: '${counts[statuses[i]]}',
           color: colors[i % colors.length],
           radius: 50,
           titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
         )
       );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Status',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 40,
                sectionsSpace: 4,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: List.generate(statuses.length, (index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors[index % colors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(statuses[index], style: const TextStyle(fontSize: 12)),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsSection(List<AdminOrderModel> orders) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        return Container(
          padding: EdgeInsets.all(isMobile ? 24 : 32),
          decoration: BoxDecoration(
            color: AppColors.primaryBlack,
            borderRadius: BorderRadius.circular(isMobile ? 24 : 32),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlack.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Flex(
            direction: isMobile ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: isMobile ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: isMobile ? 0 : 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sales Report Generator',
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Download detailed sales analytics and performance reports.',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    ),
                    if (isMobile) const SizedBox(height: 24),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _generateReport(orders),
                icon: const Icon(Icons.description_outlined, size: 20),
                label: const Text('GENERATE PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primaryBlack,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  minimumSize: isMobile ? const Size(double.infinity, 56) : null,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _generateReport(List<AdminOrderModel> orders) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        DateTime? startDate;
        DateTime? endDate;
        String selectedStatus = 'All';
        String reportRange = 'Weekly';

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 32,
                right: 32,
                top: 32,
                bottom: MediaQuery.of(context).viewInsets.bottom + 32,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Generate Report',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Time Range',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['Today', 'Weekly', 'Monthly', 'Custom'].map((range) {
                        final isSelected = reportRange == range;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(range),
                            selected: isSelected,
                            selectedColor: AppColors.primaryBlack,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setModalState(() {
                                  reportRange = range;
                                  if (range == 'Custom') {
                                    // Custom logic handled below
                                  }
                                });
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  if (reportRange == 'Custom') ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await showDateRangePicker(
                                context: context,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.light(
                                        primary: AppColors.primaryBlack,
                                        onPrimary: Colors.white,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                setModalState(() {
                                  startDate = picked.start;
                                  endDate = picked.end;
                                });
                              }
                            },
                            icon: const Icon(Icons.date_range, size: 18),
                            label: Text(
                              startDate == null
                                  ? 'Select Dates'
                                  : '${DateFormat('dd/MM').format(startDate!)} - ${DateFormat('dd/MM').format(endDate!)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Text(
                    'Order Status',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    items: ['All', 'Pending', 'Processing', 'Shipped', 'Completed', 'Cancelled']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) => setModalState(() => selectedStatus = val!),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Filter orders based on criteria
                        DateTime now = DateTime.now();
                        DateTime filterStart;
                        DateTime filterEnd = now;

                        switch (reportRange) {
                          case 'Today':
                            filterStart = DateTime(now.year, now.month, now.day);
                            break;
                          case 'Weekly':
                            filterStart = now.subtract(const Duration(days: 7));
                            break;
                          case 'Monthly':
                            filterStart = DateTime(now.year, now.month - 1, now.day);
                            break;
                          case 'Custom':
                            filterStart = startDate ?? DateTime(2020);
                            filterEnd = endDate?.add(const Duration(days: 1)) ?? now;
                            break;
                          default:
                            filterStart = DateTime(2020);
                        }

                        List<AdminOrderModel> filteredOrders = orders.where((o) {
                          bool matchesDate = o.createdAt.isAfter(filterStart) && o.createdAt.isBefore(filterEnd);
                          bool matchesStatus = selectedStatus == 'All' || o.status.toLowerCase() == selectedStatus.toLowerCase();
                          return matchesDate && matchesStatus;
                        }).toList();

                        if (filteredOrders.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No orders found for the selected filters')),
                          );
                          return;
                        }

                        Navigator.pop(context);
                        ReportGenerator.generateSalesReport(filteredOrders);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlack,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('GENERATE PDF REPORT', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

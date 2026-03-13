import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../features/admin/model/admin_order_model.dart';

class ReportGenerator {
  static Future<void> generateSalesReport(List<AdminOrderModel> orders) async {
    final pdf = pw.Document();

    final totalRevenue = orders.fold<double>(0, (sum, o) => sum + o.totalAmount);
    final completedOrders = orders.where((o) => o.status.toLowerCase() == 'completed').length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Sri Vaari Mart - Sales Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text(DateFormat('MMM dd, yyyy').format(DateTime.now())),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildStat('Total Orders', '${orders.length}'),
                _buildStat('Completed', '$completedOrders'),
                _buildStat('Total Revenue', 'Rs. ${NumberFormat('#,##,###').format(totalRevenue)}'),
              ],
            ),
            pw.SizedBox(height: 30),
            pw.Text('Order Details', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headers: ['Order ID', 'Date', 'Amount', 'Status', 'Payment'],
              data: orders.map((o) => [
                '#${o.id.substring(0, 8)}',
                DateFormat('yyyy-MM-dd').format(o.createdAt),
                'Rs. ${o.totalAmount.toStringAsFixed(0)}',
                o.status.toUpperCase(),
                o.paymentMethod,
              ]).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerLeft,
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  static pw.Widget _buildStat(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(color: PdfColors.grey)),
        pw.Text(value, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }
}

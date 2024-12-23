import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:pdfx/pdfx.dart';
import 'package:signature/signature.dart';
import 'package:sirve_poc/pdf/customer.dart';
import 'package:sirve_poc/pdf/invoice.dart';
import 'package:sirve_poc/pdf/pdf_invoice_api.dart';
import 'package:sirve_poc/pdf/supplier.dart';

class PdfESign extends StatefulWidget {
  const PdfESign({super.key});

  @override
  State<PdfESign> createState() => _PdfESignState();
}

class _PdfESignState extends State<PdfESign> {
  late PdfControllerPinch pdfController;
  final SignatureController controller = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.blue,
    exportBackgroundColor: Colors.white,
  );
  Uint8List? firstSignatureData;
  Uint8List? secondSignatureData;
  String? path;
  ValueNotifier<bool> isPdfLoading = ValueNotifier<bool>(true);

  @override
  void initState() {
    super.initState();
    generateAndOpenPdf();
  }

  void generateAndOpenPdf() async {
    final invoice = Invoice(
      info: InvoiceInfo(
        description: 'ACME Supplies',
        number: '2020-001',
        date: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(days: 7)),
      ),
      supplier: const Supplier(
        name: 'ACME Supplies',
        address: '123 Main Street',
        paymentInfo: '',
      ),
      customer: const Customer(
        name: 'John Doe',
        address: '456 Oak Road',
      ),
      items: List.generate(
        5,
        (index) => InvoiceItem(
          description: 'Product ${index + 1}',
          date: DateTime.now(),
          quantity: (index + 1) * 10,
          vat: 0.19,
          unitPrice: (index + 1) * 10.0,
        ),
      ),
    );
    final pdfFile = await PdfInvoiceApi.generate(
        invoice, firstSignatureData, secondSignatureData);
    setState(() {
      if (firstSignatureData == null) {
        firstSignatureData = firstSignatureData;
      } else {
        secondSignatureData = secondSignatureData;
      }
      path = pdfFile.path;
      pdfController =
          PdfControllerPinch(document: PdfDocument.openFile(pdfFile.path));
    });
    isPdfLoading.value = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('PDF E-Sign'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              // ignore: use_build_context_synchronously
              context,
              '/home',
              (route) => false,
              arguments: '', // Pass the path to the PDF file
            );
          },
        ),
      ),
      body: Column(
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: isPdfLoading,
            builder: (context, isLoading, child) {
              return isLoading
                  ? const Expanded(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Colors.blue,
                        ),
                      ),
                    )
                  : Expanded(
                      // child: PdfViewPinch(controller: pdfController),
                      child: PDFView(
                        filePath: path,
                        enableSwipe: true,
                        swipeHorizontal: true,
                        autoSpacing: false,
                        pageFling: false,
                        backgroundColor: Colors.grey,
                        onRender: (_pages) {},
                        onError: (error) {
                          print(error.toString());
                        },
                        onPageError: (page, error) {
                          print('$page: ${error.toString()}');
                        },
                        onViewCreated: (PDFViewController pdfViewController) {},
                      ),
                    );
            },
          ),
        ],
      ),
      floatingActionButton: Column(
        children: [
          const Spacer(),
          SizedBox(
            height: 40,
            width: 70,
            child: TextButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.blue),
                foregroundColor: MaterialStateProperty.all(Colors.white),
              ),
              onPressed: () {
                // generateNewPdf();
                _showEditDialog(context);
              },
              child: const Text('1 Sign'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            width: 70,
            child: TextButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.blue),
                foregroundColor: MaterialStateProperty.all(Colors.white),
              ),
              onPressed: () {
                _showEditDialog(context);
              },
              child: const Text('2 Sign'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> generateNewPdf() async {
    if (path == null) return;
    isPdfLoading.value = true;
    final existingPdf = await PdfDocument.openFile(path!);
    final pdf = pw.Document();

    // Add existing pages to the new PDF with high resolution
    for (int i = 0; i < existingPdf.pagesCount; i++) {
      final page = await existingPdf.getPage(i + 1);
      final pageImage = await page.render(
        width: page.width * 2, // Increase resolution
        height: page.height * 2, // Increase resolution
        format: PdfPageImageFormat.png,
      );
      final pageImageBytes = pageImage!.bytes;
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.FullPage(
              ignoreMargins: true,
              child: pw.Image(pw.MemoryImage(pageImageBytes)),
            );
          },
        ),
      );
      await page.close();
    }

    // Add new content to the new PDF
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Text('New Content', style: pw.TextStyle(fontSize: 24)),
              if (firstSignatureData != null)
                pw.Image(pw.MemoryImage(firstSignatureData!)),
              if (secondSignatureData != null)
                pw.Image(pw.MemoryImage(secondSignatureData!)),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final newPdfFile = File("${output.path}/new_invoice.pdf");
    await newPdfFile.writeAsBytes(await pdf.save());

    setState(() {
      path = newPdfFile.path;
      pdfController =
          PdfControllerPinch(document: PdfDocument.openFile(newPdfFile.path));
    });
    isPdfLoading.value = false;
  }

  void _showEditDialog(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            width: screenWidth - 50,
            height: 550,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text(
                  'Sign Here',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Signature(
                  controller: controller,
                  height: 300,
                  backgroundColor: Colors.black,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      onPressed: () {
                        controller.undo();
                      },
                      icon: const Icon(Icons.undo),
                    ),
                    IconButton(
                      onPressed: () {
                        controller.redo();
                      },
                      icon: const Icon(Icons.redo),
                    ),
                    TextButton(
                      onPressed: () {
                        controller.clear();
                      },
                      child: const Text('Clear'),
                    ),
                    TextButton(
                      onPressed: () async {
                        isPdfLoading.value = true;
                        final signatureImage = await controller.toPngBytes();
                        final invoice = Invoice(
                          info: InvoiceInfo(
                            description: 'ACME Supplies',
                            number: '2020-001',
                            date: DateTime.now(),
                            dueDate:
                                DateTime.now().add(const Duration(days: 7)),
                          ),
                          supplier: const Supplier(
                            name: 'ACME Supplies',
                            address: '123 Main Street',
                            paymentInfo: '',
                          ),
                          customer: const Customer(
                            name: 'John Doe',
                            address: '456 Oak Road',
                          ),
                          items: List.generate(
                            5,
                            (index) => InvoiceItem(
                              description: 'Product ${index + 1}',
                              date: DateTime.now(),
                              quantity: (index + 1) * 10,
                              vat: 0.19,
                              unitPrice: (index + 1) * 10.0,
                            ),
                          ),
                        );
                        setState(() {
                          if (firstSignatureData == null) {
                            firstSignatureData = signatureImage;
                          } else {
                            secondSignatureData = signatureImage;
                          }
                        });
                        final pdfFile = await PdfInvoiceApi.generate(
                            invoice, firstSignatureData, secondSignatureData);
                        setState(() {
                          path = pdfFile.path;
                          pdfController = PdfControllerPinch(
                              document: PdfDocument.openFile(pdfFile.path));
                        });
                        isPdfLoading.value = false;
                        controller.clear();
                        Navigator.pop(context);
                      },
                      child: const Text('Save'),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }
}

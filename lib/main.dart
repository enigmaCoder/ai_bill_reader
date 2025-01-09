import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:js' as js;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Bill Reader',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: InvoiceAnalyzer(),
    );
  }
}

class InvoiceAnalyzer extends StatefulWidget {
  @override
  _InvoiceAnalyzerState createState() => _InvoiceAnalyzerState();
}

class _InvoiceAnalyzerState extends State<InvoiceAnalyzer> {
  PlatformFile? selectedFile;
  Map<String, dynamic>? extractedData;
  bool isLoading = false;

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        selectedFile = result.files.single;
      });
    }
  }

  Future<void> analyzeInvoice() async {
    if (selectedFile == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      final encodedFile = base64Encode(selectedFile!.bytes!);

      // Pass the encoded file to the JavaScript function for analysis
      js.context.callMethod('analyzeInvoice', [
        encodedFile,
        js.JsFunction.withThis((_, String responseJson) {
          setState(() {
            extractedData = Map<String, dynamic>.from(json.decode(responseJson));
            isLoading = false;
          });
        }),
        js.JsFunction.withThis((_, String errorMessage) {
          showError(errorMessage);
          setState(() {
            isLoading = false;
          });
        })
      ]);
    } catch (e) {
      showError('An error occurred: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget displayExtractedData() {
    if (extractedData == null) return Text('No data available.');

    return ListView(
      shrinkWrap: true,
      children: extractedData!.entries.map((entry) {
        return ListTile(
          title: Text(entry.key),
          subtitle: Text(entry.value.toString()),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Bill Reader'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: pickFile,
              child: Text('Upload Invoice'),
            ),
            SizedBox(height: 10),
            if (selectedFile != null) Text('Selected File: ${selectedFile!.name}'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: analyzeInvoice,
              child: isLoading ? CircularProgressIndicator() : Text('Analyze'),
            ),
            SizedBox(height: 20),
            Expanded(
              child: extractedData != null
                  ? displayExtractedData()
                  : Center(
                child: Text('Upload an invoice or bill to analyze.'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

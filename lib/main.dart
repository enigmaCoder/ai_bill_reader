import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

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
      final uri = Uri.parse('https://api.openai.com/v1/images/analyze'); // Update with actual endpoint
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer YOUR_OPENAI_API_KEY'
        ..files.add(http.MultipartFile.fromBytes('file', selectedFile!.bytes!, filename: selectedFile!.name));

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        setState(() {
          extractedData = json.decode(responseData);
        });
      } else {
        showError('Failed to analyze the invoice. Please try again.');
      }
    } catch (e) {
      showError('An error occurred: $e');
    } finally {
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
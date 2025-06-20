import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gradprj/core/helpers/ipconfig.dart';
import 'package:gradprj/core/theming/my_colors.dart';
import 'package:gradprj/views/home/ui/screens/note_page.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../test.dart';
import '../../../../test.dart';
import '../widgets/app_bar_home.dart';
import '../widgets/bottom_bar_home.dart';
import 'note_page.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<List<dynamic>>? _futureTranscriptions;
  String? userId;

  @override
  void initState() {
    super.initState();
    loadUserIdAndFetch();
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  Future<List<dynamic>> fetchUserTranscriptions(String userId) async {
    final url = Uri.parse('http://$ipAddress:4000/api/transcriptions/user/$userId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return data['data'];
      } else {
        throw Exception('Failed to load transcriptions: success false');
      }
    } else if (response.statusCode == 404) {
      // 404 معناه لا توجد بيانات، فترجع ليست فارغة بدل رمي استثناء
      return [];
    } else {
      throw Exception('Failed to load transcriptions: status code ${response.statusCode}');
    }
  }


  void loadUserIdAndFetch() async {
    userId = await getUserId();
    if (userId != null) {
      setState(() {
        _futureTranscriptions = fetchUserTranscriptions(userId!);
      });
    } else {
      setState(() {
        _futureTranscriptions = Future.value([]);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.backgroundColor,
      appBar: AppBarHome(),
      body: _futureTranscriptions == null
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<dynamic>>(
        future: _futureTranscriptions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
                child: Text('Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red)));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            // حالة عدم وجود بيانات - عرض رسالة وأيقونة وزر تحديث
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.note_alt_outlined, size: 80, color: MyColors.button1Color),
                  const SizedBox(height: 16),
                  const Text(
                    'No transcriptions found.',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Your transcriptions will appear here once you record or ublod file.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white38,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                ],
              ),
            );
          } else {
            final transcriptions = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              itemCount: transcriptions.length,
              itemBuilder: (context, index) {
                final item = transcriptions[index];
                final uploadDate = item['upload_date'];
                DateTime? parsedDate;
                if (uploadDate != null) {
                  parsedDate = DateTime.tryParse(uploadDate);
                }
                String transcriptionPreview = (item['transcription'] ?? "");
                if (transcriptionPreview.length > 50) {
                  transcriptionPreview = transcriptionPreview.substring(0, 50) + "...";
                }

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 6,
                  shadowColor: MyColors.whiteColor,
                  color: MyColors.backgroundColor,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    title: Text(
                      transcriptionPreview,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Text(
                      parsedDate != null
                          ? " ${DateFormat.yMMMd().add_jm().format(parsedDate)}"
                          : "Uploaded on: Unknown",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => note_screen(
                            uploadDate: parsedDate,
                            fullTranscription: item['transcription'] ?? '',
                          ),
                        ),
                      );
                      loadUserIdAndFetch();
                    },


                  ),
                );
              },
            );
          }
        },
      ),
      bottomNavigationBar: SizedBox(
        height: 100,
        child: BottomBarHome(
          onDataChanged: () {
            loadUserIdAndFetch();
          },
        ),
      ),
    );
  }
}

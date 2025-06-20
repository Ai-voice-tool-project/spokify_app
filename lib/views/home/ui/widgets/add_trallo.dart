import 'package:shared_preferences/shared_preferences.dart';


import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../../core/helpers/ipconfig.dart';
import '../../../../core/theming/my_colors.dart';

Future<String?> getTrelloToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('trello_token');
}
Future<bool> addTasksToTrello({
  required String boardName,
  required String listName,
  List<String> members = const [],
}) async {
  try {
    final token = await getTrelloToken();
    if (token == null) {
      print("No Trello token found");
      return false;
    }

    final dio = Dio();
    final response = await dio.post(
      'http://$ipAddress:8000/extract_and_add_tasks/',
      data: {
        "board_name": boardName,
        "list_name": listName,
        "members": members,
        "user_token": token,
      },
      options: Options(
        headers: {"Content-Type": "application/json"},
        contentType: Headers.jsonContentType,
      ),
    );

    return response.statusCode == 200;
  } catch (e) {
    print("Error: $e");
    return false;
  }
}

void showTrelloInputDialog(BuildContext context) {
  final boardController = TextEditingController();
  final listController = TextEditingController();
  List<TextEditingController> memberControllers = [TextEditingController()];
  bool isLoading = false;

  showDialog(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dialogWidth = MediaQuery.of(context).size.width * 0.9;

          return StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Container(
                  width: dialogWidth,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: MyColors.backgroundColor,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade300,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Add to Trello",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: boardController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Board Name',
                          hintText: 'Enter board name',
                          labelStyle: const TextStyle(color: Colors.white),
                          hintStyle: const TextStyle(color: Colors.white54),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white24),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: listController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'List Name',
                          hintText: 'Enter list name',
                          labelStyle: const TextStyle(color: Colors.white),
                          hintStyle: const TextStyle(color: Colors.white54),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white24),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Add Members (optional)",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Column(
                        children: List.generate(memberControllers.length, (index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: memberControllers[index],
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      hintText: 'Email or username',
                                      hintStyle: const TextStyle(color: Colors.white54),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(color: Colors.white24),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle, color: Colors.redAccent),
                                  onPressed: () {
                                    setState(() {
                                      memberControllers.removeAt(index);
                                    });
                                  },
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            memberControllers.add(TextEditingController());
                          });
                        },
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text("Add Member", style: TextStyle(color: Colors.white)),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            child: const Text("Cancel", style: TextStyle(color: Colors.white)),
                            onPressed: () => Navigator.pop(context),
                          ),
                          isLoading
                              ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              : ElevatedButton(
                            onPressed: () async {
                              final boardName = boardController.text.trim();
                              final listName = listController.text.trim();

                              if (boardName.isEmpty || listName.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Please fill in both Board and List names.", style: TextStyle(color: Colors.white)),
                                    backgroundColor: MyColors.backgroundColor,
                                  ),
                                );
                                return;
                              }

                              final members = memberControllers
                                  .map((c) => c.text.trim())
                                  .where((email) => email.isNotEmpty)
                                  .toList();

                              setState(() {
                                isLoading = true;
                              });

                              final success = await addTasksToTrello(
                                boardName: boardName,
                                listName: listName,
                                members: members,
                              );

                              setState(() {
                                isLoading = false;
                              });

                              Navigator.pop(context);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? "Tasks were successfully added to Trello."
                                        : "Failed to add tasks to Trello.",
                                  ),
                                  backgroundColor: MyColors.backgroundColor,
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            },
                            child: const Text("Add"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    ),
  );
}

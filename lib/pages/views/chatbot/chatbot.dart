import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatBotUI extends StatefulWidget {
  @override
  _ChatBotUIState createState() => _ChatBotUIState();
}

class _ChatBotUIState extends State<ChatBotUI> {
  String? selectedQuestion;
  String? displayedAnswer;

  // Typewriter animation for displaying the answer
  Future<void> _showAnswer(String answer) async {
    setState(() => displayedAnswer = ''); // Reset the displayedAnswer
    for (int i = 0; i < answer.length; i++) {
      await Future.delayed(const Duration(milliseconds: 50), () {
        setState(() {
          displayedAnswer = (displayedAnswer ?? '') + answer[i];
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine screen size category
    final double screenWidth = MediaQuery.of(context).size.width;
    double heightFactor;
    double widthFactor;

    if (screenWidth >= 1024) {
      // Web/Desktop
      heightFactor = 0.75;
      widthFactor = 0.3;
    } else if (screenWidth >= 600) {
      // Tablet
      heightFactor = 0.7;
      widthFactor = 0.5;
    } else {
      // Mobile
      heightFactor = 0.6;
      widthFactor = 0.9;
    }

    return Container(
      height: MediaQuery.of(context).size.height * heightFactor,
      width: MediaQuery.of(context).size.width * widthFactor,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'FAQs',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // FAQ List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('FAQs').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No FAQs available.'));
                }

                final faqs = snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return {
                    'question': data['question'] ?? '',
                    'answer': data['answer'] ?? '',
                  };
                }).toList();

                return ListView(
                  children: [
                    const Text(
                      'Hi there! Is there anything you want to know?',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: faqs.map((faq) {
                      return ElevatedButton(
                        onPressed: () {
                          setState(() => selectedQuestion = faq['question']);
                          _showAnswer(faq['answer']!);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5), // Rounded corners with 5 radius
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Optional: Adjust padding
                          foregroundColor: Colors.black
                        ),
                        child: Text(faq['question']!),
                      );
                    }).toList(),
                  ),

                    const SizedBox(height: 16),
                   if (selectedQuestion != null) ...[
                    Text(
                      selectedQuestion!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.4,
                      ),
                      child: SingleChildScrollView(
                        child: Container(
                          padding: const EdgeInsets.all(12), // Padding inside the container
                          decoration: BoxDecoration(
                            color: Colors.blue, // Background color
                            borderRadius: BorderRadius.circular(15), // Rounded corners
                          ),
                          child: Text(
                            displayedAnswer ?? '',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white, // Text color
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],

                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

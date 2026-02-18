import 'package:flutter/material.dart';
import 'add_job_screen.dart';

class Step1 extends StatefulWidget {
  final VoidCallback onNext;
  final JobData jobData;

  const Step1({
    super.key,
    required this.onNext,
    required this.jobData,
  });

  @override
  State<Step1> createState() => _Step1State();
}

class _Step1State extends State<Step1> {
  final TextEditingController titleController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    titleController.text = widget.jobData.title;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// Progress Bar
                Row(
                  children: List.generate(
                    6,
                    (index) => Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        height: 6,
                        decoration: BoxDecoration(
                          color: index == 0
                              ? const Color(0xFFF2B84B)
                              : Colors.grey.shade300,
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                const Text(
                  "What type of service do you need?",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  "Select a category or enter a service name",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 20),

                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    hintText:
                        "e.g. Cleaning, Plumbing, Electrical Work",
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(16),
                      borderSide: const BorderSide(
                          color: Color(0xFFF2B84B)),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  padding:
                      const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6E7C9),
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: const Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline,
                          color: Color(0xFFF2B84B)),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Specify the category to help us connect you with the right specialist.",
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        /// Bottom Button
        Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: () {
                widget.jobData.title =
                    titleController.text;
                widget.onNext();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFFF2B84B),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                "Save & Continue",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight:
                      FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

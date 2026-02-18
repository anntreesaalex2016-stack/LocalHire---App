import 'package:flutter/material.dart';
import 'add_job_screen.dart';

class Step4 extends StatefulWidget {
  final VoidCallback onNext;
  final JobData jobData;

  const Step4({
    super.key,
    required this.onNext,
    required this.jobData,
  });

  @override
  State<Step4> createState() => _Step4State();
}

class _Step4State extends State<Step4> {
  String selectedOption = "date";
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();

    if (widget.jobData.date != null) {
      selectedDate = widget.jobData.date!;
    }
  }

  Future<void> pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  String formattedDate() {
    return "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}";
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
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                /// Progress Bar (Step 4 active)
                Row(
                  children: List.generate(
                    6,
                    (index) => Expanded(
                      child: Container(
                        margin:
                            const EdgeInsets.symmetric(horizontal: 2),
                        height: 6,
                        decoration: BoxDecoration(
                          color: index <= 3
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
                  "When do you need?",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold),
                ),

                const SizedBox(height: 6),

                const Text(
                  "Select your preferred date",
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey),
                ),

                const SizedBox(height: 30),

                /// Date Picker
                GestureDetector(
                  onTap: () => pickDate(context),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 18),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color:
                              const Color(0xFFF2B84B),
                          width: 2),
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .spaceBetween,
                      children: [
                        Text(
                          formattedDate(),
                          style: const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                              fontSize: 16),
                        ),
                        const Icon(
                          Icons.calendar_today,
                          color:
                              Color(0xFFF2B84B),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        /// Bottom Button
        Padding(
          padding:
              const EdgeInsets.all(20),
          child: SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: () {
                widget.jobData.date =
                    selectedDate;

                widget.onNext();
              },
              style: ElevatedButton
                  .styleFrom(
                backgroundColor:
                    const Color(
                        0xFFF2B84B),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius
                          .circular(20),
                ),
              ),
              child: const Text(
                "Save & Continue",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        Colors.black),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

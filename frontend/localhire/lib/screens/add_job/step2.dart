import 'package:flutter/material.dart';
import 'add_job_screen.dart';

class Step2 extends StatefulWidget {
  final VoidCallback onNext;
  final JobData jobData;

  const Step2({
    super.key,
    required this.onNext,
    required this.jobData,
  });

  @override
  State<Step2> createState() => _Step2State();
}

class _Step2State extends State<Step2> {
  final TextEditingController descriptionController =
      TextEditingController();

  int workers = 1;

  @override
  void initState() {
    super.initState();
    descriptionController.text =
        widget.jobData.description;
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

                /// Progress Bar (Step 2 Active)
                Row(
                  children: List.generate(
                    6,
                    (index) => Expanded(
                      child: Container(
                        margin:
                            const EdgeInsets.symmetric(horizontal: 2),
                        height: 6,
                        decoration: BoxDecoration(
                          color: index <= 1
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
                  "Describe your task in detail",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 6),

                const Text(
                  "Include specific requirements and expectations",
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey),
                ),

                const SizedBox(height: 20),

                /// Description Box
                TextField(
                  controller:
                      descriptionController,
                  maxLines: 6,
                  decoration: InputDecoration(
                    hintText:
                        "Describe your task...",
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                    focusedBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(16),
                      borderSide:
                          const BorderSide(
                              color: Color(
                                  0xFFF2B84B)),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                /// Workers Counter
                const Text(
                  "Number of workers needed",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "How many people?",
                      style: TextStyle(
                          color: Colors.grey),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            if (workers > 1) {
                              setState(() {
                                workers--;
                              });
                            }
                          },
                          icon: const Icon(
                              Icons.remove),
                        ),
                        Text(
                          workers.toString(),
                          style:
                              const TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              workers++;
                            });
                          },
                          icon:
                              const Icon(Icons.add),
                        ),
                      ],
                    )
                  ],
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
                widget.jobData.description =
                    descriptionController.text;

                widget.onNext();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFFF2B84B),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                          20),
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

import 'package:flutter/material.dart';
import 'add_job_screen.dart';

class Step5 extends StatefulWidget {
  final VoidCallback onNext;
  final JobData jobData;

  const Step5({
    super.key,
    required this.onNext,
    required this.jobData,
  });

  @override
  State<Step5> createState() => _Step5State();
}

class _Step5State extends State<Step5> {
  final TextEditingController budgetController =
      TextEditingController();

  int selectedQuickAmount = 0;

  @override
  void initState() {
    super.initState();

    if (widget.jobData.budget != 0) {
      selectedQuickAmount = widget.jobData.budget;
      budgetController.text =
          widget.jobData.budget.toString();
    } else {
      budgetController.text = "500";
      selectedQuickAmount = 500;
    }
  }

  void selectQuickAmount(int amount) {
    setState(() {
      selectedQuickAmount = amount;
      budgetController.text =
          amount.toString();
    });
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

                /// Progress Bar (Step 5 active)
                Row(
                  children: List.generate(
                    6,
                    (index) => Expanded(
                      child: Container(
                        margin:
                            const EdgeInsets.symmetric(horizontal: 2),
                        height: 6,
                        decoration: BoxDecoration(
                          color: index <= 4
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
                  "Suggest Budget",
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight:
                          FontWeight.bold),
                ),

                const SizedBox(height: 6),

                const Text(
                  "What is the estimated budget?",
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey),
                ),

                const SizedBox(height: 40),

                /// Budget Input
                Center(
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      const Text(
                        "₹",
                        style: TextStyle(
                            fontSize: 40,
                            fontWeight:
                                FontWeight.bold,
                            color:
                                Color(0xFFF2B84B)),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 120,
                        child: TextField(
                          controller:
                              budgetController,
                          keyboardType:
                              TextInputType.number,
                          textAlign:
                              TextAlign.center,
                          style: const TextStyle(
                              fontSize: 36,
                              fontWeight:
                                  FontWeight.bold),
                          decoration:
                              const InputDecoration(
                            border:
                                UnderlineInputBorder(
                              borderSide:
                                  BorderSide(
                                      color: Color(
                                          0xFFF2B84B),
                                      width: 2),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                /// Quick Select Buttons
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    quickButton(200),
                    quickButton(500),
                    quickButton(1000),
                    quickButton(2000),
                  ],
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
                widget.jobData.budget =
                    int.tryParse(
                            budgetController
                                .text) ??
                        0;

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
                "Continue",
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

  Widget quickButton(int amount) {
    bool isSelected =
        selectedQuickAmount == amount;

    return GestureDetector(
      onTap: () => selectQuickAmount(amount),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? const Color(0xFFF2B84B)
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius:
              BorderRadius.circular(30),
          color: isSelected
              ? const Color(0xFFF2B84B)
                  .withOpacity(0.1)
              : Colors.white,
        ),
        child: Text(
          "₹$amount",
          style: TextStyle(
            fontWeight: isSelected
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

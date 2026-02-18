import 'package:flutter/material.dart';
import 'add_job_screen.dart';

class Step3 extends StatefulWidget {
  final VoidCallback onNext;
  final JobData jobData;

  const Step3({
    super.key,
    required this.onNext,
    required this.jobData,
  });

  @override
  State<Step3> createState() => _Step3State();
}

class _Step3State extends State<Step3> {
  String selectedMode = "offline";
  final TextEditingController locationController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedMode =
        widget.jobData.locationType.isEmpty
            ? "offline"
            : widget.jobData.locationType;

    locationController.text =
        widget.jobData.location;
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

                /// Progress Bar (Step 3 active)
                Row(
                  children: List.generate(
                    6,
                    (index) => Expanded(
                      child: Container(
                        margin:
                            const EdgeInsets.symmetric(horizontal: 2),
                        height: 6,
                        decoration: BoxDecoration(
                          color: index <= 2
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
                  "Where do you need it done?",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold),
                ),

                const SizedBox(height: 6),

                const Text(
                  "Choose if this is on-site or remote",
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey),
                ),

                const SizedBox(height: 25),

                /// Offline / Online Selection
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedMode =
                                "offline";
                          });
                        },
                        child: Container(
                          padding:
                              const EdgeInsets.all(
                                  20),
                          decoration:
                              BoxDecoration(
                            border: Border.all(
                              color:
                                  selectedMode ==
                                          "offline"
                                      ? const Color(
                                          0xFFF2B84B)
                                      : Colors
                                          .grey
                                          .shade300,
                              width: 2,
                            ),
                            borderRadius:
                                BorderRadius
                                    .circular(
                                        16),
                            color:
                                selectedMode ==
                                        "offline"
                                    ? const Color(
                                            0xFFF2B84B)
                                        .withOpacity(
                                            0.1)
                                    : Colors.white,
                          ),
                          child: const Column(
                            children: [
                              Icon(
                                  Icons
                                      .location_on,
                                  size: 30,
                                  color: Color(
                                      0xFFF2B84B)),
                              SizedBox(
                                  height: 8),
                              Text(
                                "Offline",
                                style: TextStyle(
                                    fontWeight:
                                        FontWeight
                                            .bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedMode =
                                "online";
                          });
                        },
                        child: Container(
                          padding:
                              const EdgeInsets.all(
                                  20),
                          decoration:
                              BoxDecoration(
                            border: Border.all(
                              color:
                                  selectedMode ==
                                          "online"
                                      ? const Color(
                                          0xFFF2B84B)
                                      : Colors
                                          .grey
                                          .shade300,
                              width: 2,
                            ),
                            borderRadius:
                                BorderRadius
                                    .circular(
                                        16),
                            color:
                                selectedMode ==
                                        "online"
                                    ? const Color(
                                            0xFFF2B84B)
                                        .withOpacity(
                                            0.1)
                                    : Colors.white,
                          ),
                          child: const Column(
                            children: [
                              Icon(Icons
                                  .language,
                                  size: 30,
                                  color: Color(
                                      0xFFF2B84B)),
                              SizedBox(
                                  height: 8),
                              Text(
                                "Online",
                                style: TextStyle(
                                    fontWeight:
                                        FontWeight
                                            .bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                /// Location Text Field
                TextField(
                  controller:
                      locationController,
                  decoration:
                      InputDecoration(
                    hintText:
                        "Enter location",
                    prefixIcon:
                        const Icon(Icons
                            .location_on),
                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                                  16),
                    ),
                    focusedBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                                  16),
                      borderSide:
                          const BorderSide(
                              color: Color(
                                  0xFFF2B84B)),
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
                widget.jobData
                    .locationType = selectedMode;
                widget.jobData
                        .location =
                    locationController
                        .text;

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

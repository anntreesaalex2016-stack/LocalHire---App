import 'package:flutter/material.dart';

class JobProfileScreen extends StatefulWidget {
  const JobProfileScreen({super.key});

  @override
  State<JobProfileScreen> createState() => _JobProfileScreenState();
}

class _JobProfileScreenState extends State<JobProfileScreen> {
  int selectedRating = 0;
  final TextEditingController reviewController = TextEditingController();

  List<String> reviews = [];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),

        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: const Icon(Icons.arrow_back, color: Colors.black),
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 16),
              child: Icon(Icons.more_vert, color: Colors.black),
            )
          ],
          title: const Text(
            "Worker Profile",
            style: TextStyle(color: Colors.black),
          ),
        ),

        body: Column(
          children: [

            const SizedBox(height: 20),

            const CircleAvatar(
              radius: 60,
              backgroundImage:
                  NetworkImage("https://i.pravatar.cc/150?img=12"),
            ),

            const SizedBox(height: 15),

            const Text(
              "Alex Rivera",
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFF1E8D8),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const TabBar(
                indicatorColor: Colors.transparent,
                labelColor: Color(0xFFFFB544),
                unselectedLabelColor: Colors.grey,
                tabs: [
                  Tab(text: "Hiring"),
                  Tab(text: "Working"),
                ],
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: TabBarView(
                children: [

                  /// ================= HIRING TAB =================
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        const Text(
                          "About",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Professional handyman with 8 years of experience.",
                          style: TextStyle(color: Colors.grey),
                        ),

                        const SizedBox(height: 20),

                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1E8D8),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Center(
                            child: Column(
                              children: [
                                Text(
                                  "86",
                                  style: TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFFFB544)),
                                ),
                                SizedBox(height: 4),
                                Text("JOBS COMPLETED")
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 25),

                        const Text(
                          "Rate & Review",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),

                        const SizedBox(height: 10),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            return IconButton(
                              icon: Icon(
                                index < selectedRating
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 32,
                              ),
                              onPressed: () {
                                setState(() {
                                  selectedRating = index + 1;
                                });
                              },
                            );
                          }),
                        ),

                        const SizedBox(height: 20),

                        TextField(
                          controller: reviewController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: "Write your review...",
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(16),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFFFFB544),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(30),
                              ),
                            ),
                            onPressed: () {
                              if (reviewController.text.isNotEmpty) {
                                setState(() {
                                  reviews.add(
                                      reviewController.text);
                                  reviewController.clear();
                                  selectedRating = 0;
                                });
                              }
                            },
                            child: const Text(
                              "Submit Review",
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// ================= WORKING TAB =================
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        const Text(
                          "About",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Currently managing renovation and plumbing projects across the city.",
                          style: TextStyle(color: Colors.grey),
                        ),

                        const SizedBox(height: 20),

                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1E8D8),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Center(
                            child: Column(
                              children: [
                                Text(
                                  "120",
                                  style: TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFFFB544)),
                                ),
                                SizedBox(height: 4),
                                Text("JOBS PROVIDED")
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 25),

                        const Text(
                          "Ratings Given",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),

                        const SizedBox(height: 10),

                        Row(
                          children: const [
                            Icon(Icons.star,
                                color: Colors.amber),
                            Icon(Icons.star,
                                color: Colors.amber),
                            Icon(Icons.star,
                                color: Colors.amber),
                            Icon(Icons.star,
                                color: Colors.amber),
                            Icon(Icons.star_border,
                                color: Colors.amber),
                          ],
                        ),

                        const SizedBox(height: 20),

                        const Text(
                          "Reviews",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),

                        const SizedBox(height: 10),

                        ...reviews.map(
                          (review) => Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(review),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
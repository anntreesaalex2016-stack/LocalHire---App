import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'step1.dart';
import 'step2.dart';
import 'step3.dart';
import 'step4.dart';
import 'step5.dart';
import 'step6.dart';

/// 🔥 Shared Job Model
class JobData {
  String title = "";
  String description = "";
  String locationType = "";
  String location = "";
  bool isInstant = false;
  DateTime? date;
  int budget = 0;
  bool isInstantJob = false;

  // ✅ Location coordinates for distance filtering
  double lat = 0.0;
  double lng = 0.0;
}

class AddJobScreen extends StatefulWidget {
  final String userId;

  const AddJobScreen({
    super.key,
    required this.userId,
  });

  @override
  State<AddJobScreen> createState() => _AddJobScreenState();
}

class _AddJobScreenState extends State<AddJobScreen> {
  final PageController _controller = PageController();

  JobData jobData = JobData();
  int currentPage = 0;

  void nextStep() {
    if (currentPage < 5) {
      setState(() => currentPage++);
      _controller.animateToPage(
        currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void previousStep() {
    if (currentPage > 0) {
      setState(() => currentPage--);
      _controller.animateToPage(
        currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> submitJob() async {
    debugPrint("====== JOB DATA ======");
    debugPrint("Title: ${jobData.title}");
    debugPrint("Description: ${jobData.description}");
    debugPrint("Location Type: ${jobData.locationType}");
    debugPrint("Location: ${jobData.location}");
    debugPrint("Lat: ${jobData.lat}, Lng: ${jobData.lng}");
    debugPrint("Date: ${jobData.date}");
    debugPrint("Budget: ${jobData.budget}");
    debugPrint("Instant Job: ${jobData.isInstantJob}");

    try {
      await FirebaseFirestore.instance.collection('jobs').add({
        'title': jobData.title,
        'description': jobData.description,
        'locationType': jobData.locationType,
        'location': jobData.location,

        // ✅ GeoPoint for distance-based filtering
        'locationGeoPoint': jobData.lat != 0.0 && jobData.lng != 0.0
            ? GeoPoint(jobData.lat, jobData.lng)
            : null,

        'date': jobData.date != null
            ? Timestamp.fromDate(jobData.date!)
            : null,
        'budget': jobData.budget,
        'isInstantJob': jobData.isInstantJob,
        'employerId': widget.userId,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("Error saving job: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to post job: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: previousStep,
        ),
        title: Text(
          "Add a Job - Step ${currentPage + 1} of 6",
          style: const TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),

      body: PageView(
        controller: _controller,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          Step1(onNext: nextStep, jobData: jobData),
          Step2(onNext: nextStep, jobData: jobData),
          Step3(onNext: nextStep, jobData: jobData),
          Step4(onNext: nextStep, jobData: jobData),
          Step5(onNext: nextStep, jobData: jobData),
          Step6(
            onNext: submitJob,
            jobData: jobData,
            userId: widget.userId,
          ),
        ],
      ),
    );
  }
}
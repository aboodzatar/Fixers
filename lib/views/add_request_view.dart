import 'dart:io';
import 'package:firebase_training/controllers/request_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class AddRequestView extends StatelessWidget {
  AddRequestView({super.key});

  final RequestController reqController = Get.find<RequestController>();
  final deviceCtrl = TextEditingController();
  final issueCtrl = TextEditingController();
  final RxList<XFile> selectedImages = <XFile>[].obs;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      selectedImages.addAll(images);
    }
  }

  void _submit() async {
    if (deviceCtrl.text.isEmpty || issueCtrl.text.isEmpty) {
      Get.snackbar('Error', 'Please fill all fields');
      return;
    }

    List<String> urls = [];
    if (selectedImages.isNotEmpty) {
      urls = await reqController.uploadImages(selectedImages);
    }

    await reqController.submitRequest(
      deviceType: deviceCtrl.text,
      issue: issueCtrl.text,
      imageUrls: urls,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.close_rounded),
          style: IconButton.styleFrom(backgroundColor: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.indigo.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.add_task_rounded,
                size: 32,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'New Maintenance\nRequest',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: 32,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: deviceCtrl,
              decoration: const InputDecoration(
                hintText: 'What device is it?',
                prefixIcon: Icon(Icons.devices_rounded),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: issueCtrl,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Describe the issue...',
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 80),
                  child: Icon(Icons.description_outlined),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Attach Photos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Obx(() => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...selectedImages.map((file) => Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(File(file.path), width: 80, height: 80, fit: BoxFit.cover),
                    ),
                    Positioned(
                      right: -5,
                      top: -5,
                      child: IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red, size: 20),
                        onPressed: () => selectedImages.remove(file),
                      ),
                    )
                  ],
                )),
                GestureDetector(
                  onTap: _pickImages,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                    ),
                    child: const Icon(Icons.add_a_photo_outlined, color: Colors.grey),
                  ),
                ),
              ],
            )),
            const SizedBox(height: 40),
            Obx(
              () =>
                  reqController.isLoading.value
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                        ),
                        child: const Text(
                          'Submit Request',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

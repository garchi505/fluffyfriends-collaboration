import 'dart:typed_data';                      // Uint8List — raw byte data for images
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // opens the device's photo gallery
import 'package:flutter_image_compress/flutter_image_compress.dart'; // compresses images before uploading
import '../services/firebase_service.dart';    // to save the post to Firestore

// ─────────────────────────────────────────────────────────────────────────────
// CreatePostScreen — where users write a caption and/or pick a photo to post.
// Opens as a modal overlay from the "+" button in the bottom nav bar.
//
// WHY WE COMPRESS IMAGES:
// Firestore has a 1MB limit per document. Raw photos from phones can be 3-10MB.
// We use flutter_image_compress to shrink images to ~50-200KB before saving.
// The image is stored as a List<int> (array of byte values) in Firestore.
//
// POSTING FLOW:
//   1. User picks a photo → we compress it → show preview
//   2. User taps Post → we validate → save to Firestore → close screen
// ─────────────────────────────────────────────────────────────────────────────

class CreatePostScreen extends StatefulWidget {
  final Map<String, dynamic> currentUser; // logged-in user's Firestore profile
  final VoidCallback onPostCreated;       // called after posting so HomeScreen refreshes

  const CreatePostScreen({
    super.key,
    required this.currentUser,
    required this.onPostCreated,
  });

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _captionController = TextEditingController(); // captures the caption text
  Uint8List? _imageBytes;  // raw bytes of the selected + compressed image (null = no image)
  bool _isPosting = false; // true while saving to Firestore — disables Post button

  // Opens the device's photo gallery and compresses the selected image.
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final result = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80, // initial compression from image_picker (we compress further below)
    );

    if (result != null) {
      final rawBytes = await result.readAsBytes(); // read the raw image file into memory

      // Compress further using flutter_image_compress.
      // minWidth/minHeight = max dimensions (800x800px).
      // quality: 50 = 50% JPEG quality — looks good on screen, much smaller file.
      // format: JPEG because it compresses better than PNG for photos.
      final compressed = await FlutterImageCompress.compressWithList(
        rawBytes,
        minWidth:  800,
        minHeight: 800,
        quality:   50,
        format:    CompressFormat.jpeg,
      );

      // Log the compressed size in the terminal so we can monitor it
      print('COMPRESSED SIZE: ${(compressed.lengthInBytes / 1024).toStringAsFixed(1)} KB');

      // Warn the user if the image is still large after compression
      if (compressed.lengthInBytes > 400 * 1024 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image is still large — try a smaller photo.'),
            duration: Duration(seconds: 3),
          ),
        );
      }

      setState(() => _imageBytes = compressed); // triggers a rebuild to show the preview
    }
  }

  // Called when the user taps the "Post" button in the app bar.
  Future<void> _post() async {
    final caption = _captionController.text.trim();

    // At least one of image or caption must be provided
    if (_imageBytes == null && caption.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a photo or write something!')),
      );
      return;
    }

    // Block the post if the image is over 700KB.
    // Firestore has a 1MB limit and the other fields take up some space too.
    if (_imageBytes != null && _imageBytes!.lengthInBytes > 700 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image is too large. Please choose a smaller photo.'),
        ),
      );
      return;
    }

    setState(() => _isPosting = true); // show "Posting..." in the button

    try {
      print('POSTING... size: ${(_imageBytes?.lengthInBytes ?? 0) / 1024} KB');

      // Save the post to Firestore via FirebaseService
      await FirebaseService.createPost(
        userId:     widget.currentUser['uid'],      // links post to the logged-in user
        username:   widget.currentUser['username'], // cached so feed doesn't need a user lookup
        caption:    caption,
        imageBytes: _imageBytes?.toList(), // Uint8List → List<int> for Firestore storage
      );

      print('POST SUCCESS');
      widget.onPostCreated(); // tell HomeScreen to refresh (triggers setState)
      if (mounted) Navigator.pop(context); // close this screen and return to the feed

    } catch (e) {
      // If Firestore rejects the write (e.g. too large, no permission), show the error
      print('POST ERROR: $e');
      if (mounted) {
        setState(() => _isPosting = false); // re-enable the Post button
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post: ${e.toString()}')),
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
        elevation: 0, // no shadow line under the app bar
        leading: IconButton(
          // X button on the left — discards the post and goes back
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('New Post',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            // "Post" button on the right — disabled while saving (prevents double-tap)
            onPressed: _isPosting ? null : _post,
            child: Text(
              _isPosting ? 'Posting...' : 'Post', // label changes while saving
              style: const TextStyle(
                  color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView( // scrollable so keyboard doesn't cover the input
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Current user's avatar and username ──────────────────────────
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.grey.shade300,
                  child: const Icon(Icons.person, color: Colors.white), // placeholder avatar
                ),
                const SizedBox(width: 12),
                // currentUser is a Map from Firestore — access fields with ['key']
                Text(widget.currentUser['username'],
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),

            // ── Caption text input ───────────────────────────────────────────
            TextField(
              controller: _captionController,
              maxLines: 4,        // allows multi-line captions
              decoration: const InputDecoration(
                hintText: "What's your stuffed toy up to? 🧸",
                border: InputBorder.none, // no visible border — clean look
                hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),

            // ── Image preview — only shown after user picks a photo ──────────
            if (_imageBytes != null) ...[
              // Show the compressed size so the user knows it's ready to post
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Image size: ${(_imageBytes!.lengthInBytes / 1024).toStringAsFixed(0)} KB',
                  style: TextStyle(
                    fontSize: 12,
                    // Red text if image is dangerously close to the 700KB limit
                    color: _imageBytes!.lengthInBytes > 700 * 1024
                        ? Colors.red
                        : Colors.grey.shade500,
                  ),
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(12), // rounded corners on preview
                child: Image.memory(
                  _imageBytes!,          // display the compressed bytes directly
                  width: double.infinity,
                  height: 300,
                  fit: BoxFit.cover,     // crop to fill the space without stretching
                ),
              ),
              const SizedBox(height: 12),
              // Button to remove the photo if the user changes their mind
              TextButton.icon(
                onPressed: () => setState(() => _imageBytes = null), // clears the image
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text('Remove photo', style: TextStyle(color: Colors.red)),
              ),
            ],

            const Divider(),
            const SizedBox(height: 12),

            // ── Add/Change photo button ──────────────────────────────────────
            GestureDetector(
              onTap: _pickImage, // opens the gallery
              child: Row(
                children: [
                  Icon(Icons.photo_library_outlined,
                      color: Colors.green.shade600, size: 28),
                  const SizedBox(width: 12),
                  // Label switches based on whether a photo is already chosen
                  Text(_imageBytes == null ? 'Add Photo' : 'Change Photo',
                      style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Tip shown at the bottom of the screen
            Text(
              'Tip: images are compressed automatically before uploading.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }
}

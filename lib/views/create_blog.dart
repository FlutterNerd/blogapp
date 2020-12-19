import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:random_string/random_string.dart';

class CreateBlog extends StatefulWidget {
  @override
  _CreateBlogState createState() => _CreateBlogState();
}

class _CreateBlogState extends State<CreateBlog> {
  TextEditingController authorTextEditingController = TextEditingController();
  TextEditingController titleTextEditingController = TextEditingController();
  TextEditingController descTextEditingController = TextEditingController();

  String imageUrl;

  bool isLoading = false;

  File _selectedImage;
  final picker = ImagePicker();

  Future getImage() async {
    final pickedFile = await picker.getImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _selectedImage = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  addBlog() async {
// make sure we have image
    if (_selectedImage != null) {
      setState(() {
        isLoading = true;
      });
      // upload image
      FirebaseStorage storage = FirebaseStorage.instance;

      Reference storageReference =
          storage.ref().child("/blogImages/${randomAlphaNumeric(20)}.jpg");

      UploadTask uploadTask = storageReference.putFile(_selectedImage);

      // get download url
      await uploadTask.whenComplete(() async {
        try {
          imageUrl = await storageReference.getDownloadURL();
          print(imageUrl);
        } catch (e) {
          print(e);
        }
      });

      Map<String, dynamic> blogData = {
        "author": authorTextEditingController.text,
        "desc": descTextEditingController.text,
        "title": titleTextEditingController.text,
        "imgUrl": imageUrl,
        "time": DateTime.now().millisecond
      };

      // upload to firebase
      FirebaseFirestore.instance
          .collection("blogs")
          .add(blogData)
          .catchError((onError) {
        print("Facing Issue while uploading data to firestore : $onError");
      });

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Create Blog"),
        ),
        body: isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _selectedImage == null
                          ? GestureDetector(
                              onTap: () {
                                getImage();
                              },
                              child: Container(
                                margin: EdgeInsets.symmetric(vertical: 16),
                                height: 180,
                                width: MediaQuery.of(context).size.width,
                                decoration: BoxDecoration(
                                    color: Colors.grey,
                                    borderRadius: BorderRadius.circular(8)),
                                child: Icon(
                                  Icons.add_a_photo,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : Container(
                              margin: EdgeInsets.symmetric(vertical: 16),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _selectedImage,
                                  height: 180,
                                  width: MediaQuery.of(context).size.width,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                      TextField(
                        controller: authorTextEditingController,
                        decoration: InputDecoration(hintText: "author name"),
                      ),
                      TextField(
                        controller: titleTextEditingController,
                        decoration: InputDecoration(hintText: "title"),
                      ),
                      TextField(
                        controller: descTextEditingController,
                        decoration: InputDecoration(hintText: "description"),
                        maxLines: 3,
                      )
                    ],
                  ),
                ),
              ),
        floatingActionButton: FloatingActionButton(
            onPressed: () {
              addBlog();
            },
            child: Icon(
              Icons.file_upload,
            )));
  }
}

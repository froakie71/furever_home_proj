import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:io';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  AuthBloc() : super(AuthInitial()) {
    on<SignInRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        await _auth.signInWithEmailAndPassword(
          email: event.email,
          password: event.password,
        );
        emit(Authenticated());
      } catch (e) {
        emit(AuthError(e.toString()));
      }
    });

    on<SignUpRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        // Create user account
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: event.email,
          password: event.password,
        );

        String? imageUrl;
        // Upload image if provided
        if (event.imageFile != null) {
          // Create a unique file name using timestamp
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final fileName = 'user_images/${userCredential.user!.uid}_$timestamp';

          // Upload for web
          final ref = _storage.ref().child(fileName);
          if (event.imageFile is File) {
            // Handle mobile file upload
            final uploadTask = await ref.putFile(
              event.imageFile!,
              SettableMetadata(contentType: 'image/jpeg'),
            );

            // Get download URL
            if (uploadTask.state == TaskState.success) {
              imageUrl = await ref.getDownloadURL();
            }
          } else {
            // Upload for other platforms
            final metadata = SettableMetadata(
              contentType: 'image/jpeg',
              customMetadata: {'picked-file-path': fileName},
            );

            await ref.putBlob(event.imageFile, metadata);
            imageUrl = await ref.getDownloadURL();
          }
        }

        // Store user data with image URL in Firestore
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          ...event.userData,
          'profileImage': imageUrl,
          'uid': userCredential.user!.uid,
        });

        emit(Authenticated());
      } catch (e) {
        emit(AuthError(e.toString()));
      }
    });

    on<SignOutRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        await _auth.signOut();
        emit(UnAuthenticated());
      } catch (e) {
        emit(AuthError(e.toString()));
      }
    });

    on<GoogleSignInRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          emit(AuthError('Google Sign In was canceled'));
          return;
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final userCredential = await _auth.signInWithCredential(credential);

        if (userCredential.user != null) {
          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .set({
                'fullName': userCredential.user!.displayName ?? '',
                'email': userCredential.user!.email ?? '',
                'profileImage': userCredential.user!.photoURL ?? '',
                'createdAt': FieldValue.serverTimestamp(),
                'lastLogin': FieldValue.serverTimestamp(),
                'provider': 'google',
              }, SetOptions(merge: true));

          emit(Authenticated());
        }
      } on PlatformException catch (e) {
        emit(AuthError('Platform Error: ${e.message}'));
      } on FirebaseAuthException catch (e) {
        emit(AuthError('Auth Error: ${e.message}'));
      } catch (e) {
        emit(AuthError(e.toString()));
      }
    });
  }

  Future<String?> uploadImage(File imageFile) async {
    try {
      final String fileName =
          'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference ref = _storage.ref().child('profile_images/$fileName');
      final UploadTask uploadTask = ref.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }
}

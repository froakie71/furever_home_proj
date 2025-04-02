import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

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
          final ref = _storage.ref().child(
            'user_images/${userCredential.user!.uid}_$timestamp.jpg',
          );

          // Upload the file
          final uploadTask = await ref.putFile(
            event.imageFile!,
            SettableMetadata(contentType: 'image/jpeg'),
          );

          // Get download URL
          if (uploadTask.state == TaskState.success) {
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
  }
}

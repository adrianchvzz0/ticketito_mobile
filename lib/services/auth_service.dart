import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<User?> signInWithGoogle() async {
    try {
      // Cerrar sesión previa de Google si existe
      await _googleSignIn.signOut();

      final GoogleSignInAccount? gUser = await _googleSignIn.signIn();
      if (gUser == null) return null; // Usuario canceló el login

      final GoogleSignInAuthentication gAuth = await gUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print(
          'FirebaseAuthException en Google Sign In: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      print('Error en Google Sign In: $e');
      return null;
    }
  }

  Future<User?> registerWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException en registro: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      print('Error en registro: $e');
      return null;
    }
  }

  Future<User?> loginWithEmail(String email, String password) async {
    try {
      // Validación básica antes de llamar a Firebase
      if (email.isEmpty || password.isEmpty) {
        print('Email o contraseña vacíos');
        return null;
      }

      // Agregar delay para evitar problemas de timing
      await Future.delayed(const Duration(milliseconds: 100));

      final userCredential = await _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password.trim());
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException en login: ${e.code} - ${e.message}');
      // Puedes manejar códigos de error específicos aquí
      switch (e.code) {
        case 'channel-error':
          print('Error de comunicación con Firebase - reintentando...');
          // Reintentar una vez después del channel-error
          await Future.delayed(const Duration(milliseconds: 500));
          try {
            final retryCredential = await _auth.signInWithEmailAndPassword(
                email: email.trim(), password: password.trim());
            return retryCredential.user;
          } catch (retryError) {
            print('Error en reintento: $retryError');
            return null;
          }
        case 'invalid-credential':
          print('Credenciales incorrectas');
          break;
        case 'user-not-found':
          print('Usuario no encontrado');
          break;
        case 'wrong-password':
          print('Contraseña incorrecta');
          break;
        case 'invalid-email':
          print('Email inválido');
          break;
        default:
          print('Error de autenticación: ${e.message}');
      }
      return null;
    } catch (e) {
      print('Error en login: $e');
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      print('Error al cerrar sesión: $e');
    }
  }

  // Método auxiliar para obtener errores más descriptivos
  String getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'invalid-credential':
        return 'Email o contraseña incorrectos';
      case 'user-not-found':
        return 'No existe una cuenta con este email';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      case 'invalid-email':
        return 'Email inválido';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada';
      case 'too-many-requests':
        return 'Demasiados intentos fallidos. Intenta más tarde';
      case 'operation-not-allowed':
        return 'Operación no permitida';
      default:
        return 'Error de autenticación';
    }
  }
}

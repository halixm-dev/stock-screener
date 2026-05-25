# BLoC Implementation Examples

## 1. Complex State Handling with Part Directives (BLoC)
```dart
// --- auth_bloc.dart ---
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService authService;

  AuthBloc({required this.authService}) : super(AuthInitial()) {
    on<SignInRequested>(_onSignInRequested);
  }

  Future<void> _onSignInRequested(SignInRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading()); // Mandatory loading state
    try {
      final user = await authService.signIn(event.email, event.password);
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}

// --- auth_event.dart ---
part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class SignInRequested extends AuthEvent {
  final String email;
  final String password;
  const SignInRequested(this.email, this.password);
  @override
  List<Object?> get props => [email, password];
}

// --- auth_state.dart ---
part of 'auth_bloc.dart';

sealed class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}
class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class Authenticated extends AuthState {
  final User user;
  const Authenticated(this.user);
  @override
  List<Object?> get props => [user];
}
class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object?> get props => [message];
}
```

## 2. Form Architecture with BLoC
```dart
// --- login_form_bloc.dart ---
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'login_form_event.dart';
part 'login_form_state.dart';

class LoginFormBloc extends Bloc<LoginFormEvent, LoginFormState> {
  LoginFormBloc() : super(const LoginFormState()) {
    on<EmailChanged>((event, emit) {
      final emailError = validateEmail(event.email);
      emit(state.copyWith(
        email: event.email,
        errors: {...state.errors, 'email': emailError},
      ));
    });
    
    on<FormSubmitted>((event, emit) async {
      emit(state.copyWith(status: FormStatus.submitting));
      // Submit logic...
      emit(state.copyWith(status: FormStatus.success));
    });
  }
}

// Domain Validator
String? validateEmail(String value) => value.contains('@') ? null : 'Invalid email';

// --- login_form_state.dart ---
part of 'login_form_bloc.dart';

enum FormStatus { initial, submitting, success, failure }

class LoginFormState extends Equatable {
  final String email;
  final String password;
  final Map<String, String?> errors;
  final FormStatus status;

  const LoginFormState({
    this.email = '',
    this.password = '',
    this.errors = const {},
    this.status = FormStatus.initial,
  });

  LoginFormState copyWith({
    String? email,
    String? password,
    Map<String, String?>? errors,
    FormStatus? status,
  }) {
    return LoginFormState(
      email: email ?? this.email,
      password: password ?? this.password,
      errors: errors ?? this.errors,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [email, password, errors, status];
}
```
